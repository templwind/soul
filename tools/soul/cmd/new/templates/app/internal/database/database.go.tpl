package database

import (
	"errors" // Import errors package
	"log"
	"os"
	"time"

	"{{.ServiceName}}/internal/dbmodels"
	"{{.ServiceName}}/internal/models"
	"{{.ServiceName}}/internal/svc"

	_ "{{.ServiceName}}/internal/registry" // Triggers module registration

	"gorm.io/gorm"

	// Stripe imports
	stripe "github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/price"
	"github.com/stripe/stripe-go/v76/product"
)

// InitDatabase initializes the database connection using GORM
func InitDatabase(svcCtx *svc.ServiceContext) {
	var err error

	// Ensure uuid-ossp extension is enabled (idempotent)
	if err := svcCtx.DB.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`).Error; err != nil {
		log.Fatalf("Failed to enable uuid-ossp extension: %v", err)
	}
	log.Println("uuid-ossp extension enabled successfully.")

	sqlDB, err := svcCtx.DB.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying sql.DB: %v", err)
	}
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// Collect core models
	coreModels := []interface{}{
		&models.User{},
		&models.Plan{},
		&models.Subscription{},
		&models.SubscriptionItem{},
		&models.Team{},
		&models.Membership{},
		&models.Invitation{},
		&models.Notification{},
		&models.BlogPost{},
		&models.Tag{},
		&models.Category{},
		&models.Communication{},
		&models.Setting{},
	}

	// Get module models
	moduleModels := dbmodels.GetAllModels()
	allModels := append(coreModels, moduleModels...)

	// Run GORM AutoMigrate
	err = svcCtx.DB.AutoMigrate(allModels...)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
	log.Println("Database migration completed successfully.")

	// Seed default settings keys (does not overwrite values)
	if err := models.SeedDefaultSettings(svcCtx.DB, models.DefaultSettings); err != nil {
		log.Printf("Failed to seed default settings: %v", err)
	} else {
		log.Println("Default settings seeded (keys ensured).")
	}

	// Sync plans with Stripe after migration
	syncPlansWithStripe(svcCtx.DB)

	// Create initial admin user if none exists
	createInitialAdminUser(svcCtx.DB)
}

// syncPlansWithStripe ensures local plan definitions exist and optionally syncs with Stripe.
func syncPlansWithStripe(db *gorm.DB) {
	log.Println("Seeding local plans...")

	// Define desired plans
	desiredPlans := []models.Plan{
		{
			ID:           "free",
			Name:         "Free",
			Features:     models.MarshalJSONFeatures([]string{"Basic Features", "Limited Usage"}),
			PriceMonthly: 0.00,
			Active:       true, // Ensure Active is true here
		},
		{
			ID:           "indie",
			Name:         "Indie",
			Features:     models.MarshalJSONFeatures([]string{"All Free Features", "Increased Usage Limits", "Team Collaboration (Up to 5 members)"}),
			PriceMonthly: 7.00,
			PriceYearly:  floatPtr(70.00),
			Active:       true, // Ensure Active is true here
		},
		{
			ID:           "pro",
			Name:         "Pro",
			Features:     models.MarshalJSONFeatures([]string{"All Indie Features", "Highest Usage Limits", "Unlimited Team Members", "Priority Support"}),
			PriceMonthly: 20.00,
			PriceYearly:  floatPtr(200.00),
			Active:       true, // Ensure Active is true here
		},
		// Add other plans as needed
	}

	// --- Seed Local Database ---
	for _, desiredPlan := range desiredPlans {
		log.Printf("Ensuring local plan exists: %s (%s)", desiredPlan.ID, desiredPlan.Name)
		var existingPlan models.Plan
		// Try to find the plan by ID
		err := db.Where("id = ?", desiredPlan.ID).First(&existingPlan).Error

		if err != nil && err == gorm.ErrRecordNotFound {
			// Plan doesn't exist, create it
			log.Printf("Creating local plan: %s", desiredPlan.ID)
			// Use the desiredPlan directly as it already has Active: true
			if createErr := db.Create(&desiredPlan).Error; createErr != nil {
				log.Printf("ERROR creating local plan %s: %v", desiredPlan.ID, createErr)
			} else {
				log.Printf("Successfully created local plan: %s", desiredPlan.ID)
			}
		} else if err != nil {
			// Other error finding the plan
			log.Printf("ERROR checking for local plan %s: %v", desiredPlan.ID, err)
		} else {
			// Plan exists, ensure it's active and details match (optional update)
			log.Printf("Found existing local plan: %s. Ensuring it is active and details match.", desiredPlan.ID)
			needsUpdate := false
			if !existingPlan.Active {
				existingPlan.Active = true
				needsUpdate = true
			}
			if existingPlan.Name != desiredPlan.Name {
				existingPlan.Name = desiredPlan.Name
				needsUpdate = true
			}
			// Add other field comparisons if necessary (Features, PriceMonthly, PriceYearly)
			// Note: Comparing JSON and float pointers requires careful handling if strict updates are needed.
			// For seeding, ensuring Active=true and Name matches might be sufficient.

			if needsUpdate {
				if updateErr := db.Save(&existingPlan).Error; updateErr != nil {
					log.Printf("ERROR updating existing local plan %s: %v", desiredPlan.ID, updateErr)
				} else {
					log.Printf("Successfully updated existing local plan: %s", desiredPlan.ID)
				}
			}
		}
	}
	log.Println("Finished seeding local plans.")

	// --- Conditional Stripe Sync ---
	stripeKey := os.Getenv("STRIPE_SECRET_KEY")
	if stripeKey == "" {
		log.Println("STRIPE_SECRET_KEY not set, skipping Stripe sync.")
		return // Exit function here if no key
	}

	// If Stripe key exists, proceed with sync
	log.Println("Starting Stripe sync...")
	stripe.Key = stripeKey

	// Fetch existing active Stripe Products with app_plan_id metadata
	prodParams := &stripe.ProductListParams{}
	prodParams.Filters.AddFilter("active", "", "true")
	existingStripeProducts := make(map[string]*stripe.Product)
	iter := product.List(prodParams)
	for iter.Next() {
		p := iter.Product()
		if appPlanID, ok := p.Metadata["app_plan_id"]; ok {
			existingStripeProducts[appPlanID] = p
		}
	}
	if err := iter.Err(); err != nil {
		// Log error but don't necessarily stop the whole process,
		// maybe just skip Stripe part for this run.
		log.Printf("Error listing Stripe products: %v. Stripe sync might be incomplete.", err)
	} else {
		log.Printf("Found %d existing active Stripe products with app_plan_id metadata.", len(existingStripeProducts))
	}

	// Iterate through desired plans *again* for Stripe sync part
	for _, desiredPlan := range desiredPlans {
		// Skip free plan for Stripe sync
		if desiredPlan.ID == "free" {
			continue
		}

		// Fetch the latest local plan details (including potentially updated Stripe IDs)
		var localPlan models.Plan
		if err := db.First(&localPlan, "id = ?", desiredPlan.ID).Error; err != nil {
			log.Printf("ERROR fetching local plan %s before Stripe sync: %v", desiredPlan.ID, err)
			continue // Skip Stripe sync for this plan if fetch fails
		}

		log.Printf("Syncing Stripe Product & Prices for plan: %s", desiredPlan.ID)
		var stripeProductID string
		needsDBUpdate := false // Flag to track if *Stripe IDs* need updating in DB

		// --- Sync Product ---
		existingProd, productExists := existingStripeProducts[desiredPlan.ID]
		if productExists {
			stripeProductID = existingProd.ID
			log.Printf("Found existing Stripe product for plan %s: %s", desiredPlan.ID, stripeProductID)
			if existingProd.Name != desiredPlan.Name {
				log.Printf("Updating Stripe product name for %s", desiredPlan.ID)
				updateParams := &stripe.ProductParams{Name: stripe.String(desiredPlan.Name)}
				_, err := product.Update(stripeProductID, updateParams)
				if err != nil {
					log.Printf("ERROR updating Stripe product name for %s: %v", desiredPlan.ID, err)
				}
			}
		} else {
			log.Printf("Creating new Stripe product for plan %s", desiredPlan.ID)
			createParams := &stripe.ProductParams{
				Name:     stripe.String(desiredPlan.Name),
				Active:   stripe.Bool(true),
				Metadata: map[string]string{"app_plan_id": desiredPlan.ID},
			}
			newProd, err := product.New(createParams)
			if err != nil {
				log.Printf("ERROR creating Stripe product for plan %s: %v", desiredPlan.ID, err)
				continue // Cannot sync prices without product
			}
			log.Printf("Created Stripe product for plan %s: %s", desiredPlan.ID, newProd.ID)
			stripeProductID = newProd.ID
		}

		// --- Sync Prices ---
		if stripeProductID == "" {
			continue
		}
		log.Printf("Syncing prices for plan %s (Product: %s)...", desiredPlan.ID, stripeProductID)

		// Fetch existing active prices for this product
		priceListParams := &stripe.PriceListParams{
			Product: stripe.String(stripeProductID),
			Active:  stripe.Bool(true),
		}
		priceIter := price.List(priceListParams)
		existingMonthlyPriceID := ""
		existingYearlyPriceID := ""
		var existingMonthlyPrice *stripe.Price
		var existingYearlyPrice *stripe.Price

		for priceIter.Next() {
			p := priceIter.Price()
			if p.Recurring != nil {
				intervalMeta, okInterval := p.Metadata["interval"]
				idMeta, okID := p.Metadata["app_plan_id"]
				// Prefer matching via metadata
				if okInterval && okID && idMeta == desiredPlan.ID {
					if intervalMeta == "month" {
						existingMonthlyPriceID = p.ID
						existingMonthlyPrice = p
					} else if intervalMeta == "year" {
						existingYearlyPriceID = p.ID
						existingYearlyPrice = p
					}
				} else if p.Recurring.Interval == stripe.PriceRecurringIntervalMonth { // Fallback to interval type
					existingMonthlyPriceID = p.ID
					existingMonthlyPrice = p
				} else if p.Recurring.Interval == stripe.PriceRecurringIntervalYear {
					existingYearlyPriceID = p.ID
					existingYearlyPrice = p
				}
			}
		}
		if err := priceIter.Err(); err != nil {
			log.Printf("ERROR listing Stripe prices for product %s: %v", stripeProductID, err)
			continue
		}

		// Check/Create Monthly Price
		monthlyPriceAmount := int64(desiredPlan.PriceMonthly * 100)
		if existingMonthlyPriceID == "" {
			log.Printf("Creating monthly Stripe price for plan %s", desiredPlan.ID)
			priceCreateParams := &stripe.PriceParams{
				Product:    stripe.String(stripeProductID),
				Currency:   stripe.String(string(stripe.CurrencyUSD)),
				UnitAmount: stripe.Int64(monthlyPriceAmount),
				Recurring:  &stripe.PriceRecurringParams{Interval: stripe.String(string(stripe.PriceRecurringIntervalMonth))},
				Metadata:   map[string]string{"app_plan_id": desiredPlan.ID, "interval": "month"},
			}
			newPrice, err := price.New(priceCreateParams)
			if err != nil {
				log.Printf("ERROR creating monthly Stripe price for plan %s: %v", desiredPlan.ID, err)
			} else {
				log.Printf("Created monthly Stripe price for plan %s: %s", desiredPlan.ID, newPrice.ID)
				localPlan.StripePriceID = newPrice.ID
				needsDBUpdate = true
			}
		} else {
			if localPlan.StripePriceID != existingMonthlyPriceID {
				localPlan.StripePriceID = existingMonthlyPriceID
				needsDBUpdate = true
			}
			if existingMonthlyPrice != nil && existingMonthlyPrice.UnitAmount != monthlyPriceAmount {
				log.Printf("WARNING: Monthly price mismatch for plan %s. Stripe: %d, Local: %d. Manual update recommended.", desiredPlan.ID, existingMonthlyPrice.UnitAmount, monthlyPriceAmount)
			}
		}

		// Check/Create Yearly Price
		if desiredPlan.PriceYearly != nil {
			yearlyPriceAmount := int64(*desiredPlan.PriceYearly * 100)
			if existingYearlyPriceID == "" {
				log.Printf("Creating yearly Stripe price for plan %s", desiredPlan.ID)
				priceCreateParams := &stripe.PriceParams{
					Product:    stripe.String(stripeProductID),
					Currency:   stripe.String(string(stripe.CurrencyUSD)),
					UnitAmount: stripe.Int64(yearlyPriceAmount),
					Recurring:  &stripe.PriceRecurringParams{Interval: stripe.String(string(stripe.PriceRecurringIntervalYear))},
					Metadata:   map[string]string{"app_plan_id": desiredPlan.ID, "interval": "year"},
				}
				newPrice, err := price.New(priceCreateParams)
				if err != nil {
					log.Printf("ERROR creating yearly Stripe price for plan %s: %v", desiredPlan.ID, err)
				} else {
					log.Printf("Created yearly Stripe price for plan %s: %s", desiredPlan.ID, newPrice.ID)
					localPlan.StripePriceIDYearly = strPtr(newPrice.ID)
					needsDBUpdate = true
				}
			} else {
				if localPlan.StripePriceIDYearly == nil || *localPlan.StripePriceIDYearly != existingYearlyPriceID {
					localPlan.StripePriceIDYearly = strPtr(existingYearlyPriceID)
					needsDBUpdate = true
				}
				if existingYearlyPrice != nil && existingYearlyPrice.UnitAmount != yearlyPriceAmount {
					log.Printf("WARNING: Yearly price mismatch for plan %s. Stripe: %d, Local: %d. Manual update recommended.", desiredPlan.ID, existingYearlyPrice.UnitAmount, yearlyPriceAmount)
				}
			}
		} else { // If desired plan has no yearly price
			if localPlan.StripePriceIDYearly != nil {
				log.Printf("Removing yearly price ID from local DB for plan %s", desiredPlan.ID)
				localPlan.StripePriceIDYearly = nil
				needsDBUpdate = true
				// TODO: Optionally archive existing yearly price in Stripe
			}
		}

		// Save local plan if Stripe IDs were updated
		if needsDBUpdate {
			log.Printf("Updating local DB record for plan %s with synced Stripe IDs...", desiredPlan.ID)
			if err := db.Save(&localPlan).Error; err != nil { // Save the localPlan we modified
				log.Printf("ERROR updating local DB for plan %s: %v", desiredPlan.ID, err)
			}
		}
	}
	log.Println("Plan sync with Stripe finished.")
}

// Helper function to create a pointer to a string
func strPtr(s string) *string {
	return &s
}

// Helper function to create a pointer to a float64
func floatPtr(f float64) *float64 {
	return &f
}

// CloseDatabase closes the database connection pool.
// It's good practice to defer this in main.go.
func CloseDatabase(svcCtx *svc.ServiceContext) {
	if svcCtx.DB != nil {
		sqlDB, err := svcCtx.DB.DB()
		if err != nil {
			log.Printf("Error getting underlying DB for closing: %v", err)
			return
		}
		err = sqlDB.Close()
		if err != nil {
			log.Printf("Error closing database connection: %v", err)
		} else {
			log.Println("Database connection closed.")
		}
	}
}

// createInitialAdminUser checks if an admin user exists and creates one from env vars if not.
func createInitialAdminUser(db *gorm.DB) {
	log.Println("Checking for initial admin user...")
	var adminCount int64
	db.Model(&models.User{}).Where("role = ?", models.SystemRoleAdmin).Count(&adminCount)

	if adminCount > 0 {
		log.Println("Admin user(s) already exist.")
		return
	}

	log.Println("No admin users found. Attempting to create initial super admin...")
	adminEmail := os.Getenv("SUPER_ADMIN_EMAIL")
	adminPassword := os.Getenv("SUPER_ADMIN_PASSWORD")

	if adminEmail == "" || adminPassword == "" {
		log.Println("WARNING: SUPER_ADMIN_EMAIL or SUPER_ADMIN_PASSWORD environment variables not set. Cannot create initial admin user.")
		return
	}

	// Basic validation (could use validator package if needed)
	if len(adminPassword) < 8 {
		log.Println("WARNING: SUPER_ADMIN_PASSWORD is too short (minimum 8 characters). Cannot create initial admin user.")
		return
	}

	// Check if email is already taken by a non-admin user (unlikely but possible)
	var existingUser models.User
	err := db.Where("email = ?", adminEmail).First(&existingUser).Error
	if err == nil {
		log.Printf("WARNING: Email %s already exists for a user. Cannot create initial admin with this email.", adminEmail)
		return
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		log.Printf("ERROR: Database error checking for existing email %s: %v", adminEmail, err)
		return
	}

	// Create the admin user
	adminUser := models.User{
		Email: adminEmail,
		Role:  models.SystemRoleAdmin,
	}
	// Hash password first
	if err := adminUser.SetPassword(adminPassword); err != nil {
		log.Printf("ERROR: Failed to hash password for initial admin user: %v", err)
		return
	}

	// Generate API Key separately and handle error
	var apiKey string                         // Declare apiKey
	apiKey, keyErr := models.GenerateAPIKey() // Use := as keyErr is new
	if keyErr != nil {
		log.Printf("ERROR: Failed to generate API key for initial admin: %v", keyErr)
		// Decide if creation should fail or proceed without API key. Let's proceed.
		apiKey = "" // Ensure apiKey is empty string if generation failed
	}
	adminUser.ApiKey = apiKey // Assign generated key (or empty string)

	// Generate Default Subdomain if needed (using the existing function)
	// adminUser.DefaultSubdomain = generateRandomSubdomain()

	// --- Persist the new admin user ---
	if err := db.Create(&adminUser).Error; err != nil { // Create the user record in DB
		log.Printf("ERROR: Failed to create initial admin user %s: %v", adminEmail, err)
		return
	}

	log.Printf("Successfully created initial admin user: %s", adminEmail)

	// Removed duplicated API key generation block
	if err := db.Create(&adminUser).Error; err != nil {
		log.Printf("ERROR: Failed to create initial admin user %s: %v", adminEmail, err)
		return
	}

	log.Printf("Successfully created initial admin user: %s", adminEmail)
}
