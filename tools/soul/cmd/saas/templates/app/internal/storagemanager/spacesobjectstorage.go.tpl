package storagemanager

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/types"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/jmoiron/sqlx"
)

const (
	DigitalOceanBucketMaxSize = 250 * 1024 * 1024 * 1024 // 250 GB
	MaxBucketUsagePercentage  = 85.0
)

type StorageManager struct {
	ctx          context.Context
	Config       *config.Config
	DB           *sqlx.DB
	s3Client     *s3.S3
	bucketName   string
	uploadConfig UploadConfig
	threshold    float64
}

type UploadConfig struct {
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
	Endpoint        string
	Region          string
}

func MustNewStorageManager(ctx context.Context, c *config.Config, db *sqlx.DB, threshold float64) *StorageManager {
	sm, err := NewStorageManager(ctx, c, db, threshold)
	if err != nil {
		panic(err)
	}
	return sm
}

func NewStorageManager(ctx context.Context, c *config.Config, db *sqlx.DB, threshold float64) (*StorageManager, error) {
	var config UploadConfig
	// Choose between AWS or DigitalOcean Spaces based on your needs
	if c.DigitalOcean.BucketName != "" {
		config = UploadConfig{
			AccessKeyID:     c.DigitalOcean.AccessKeyID,
			SecretAccessKey: c.DigitalOcean.SecretAccessKey,
			BucketName:      c.DigitalOcean.BucketName,
			Endpoint:        c.DigitalOcean.Endpoint,
			Region:          c.DigitalOcean.Region,
		}
	} else {
		return nil, fmt.Errorf("no storage configuration found")
	}

	s3Client := s3.New(session.Must(session.NewSession(&aws.Config{
		Region:           aws.String(config.Region),
		Endpoint:         aws.String(config.Endpoint),
		Credentials:      credentials.NewStaticCredentials(config.AccessKeyID, config.SecretAccessKey, ""),
		S3ForcePathStyle: aws.Bool(false), // Required for DigitalOcean Spaces
	})))

	fmt.Println("Using DigitalOcean Spaces for object storage", s3Client.Config.Endpoint)

	return &StorageManager{
		ctx:          ctx,
		Config:       c,
		DB:           db,
		s3Client:     s3Client,
		bucketName:   config.BucketName,
		uploadConfig: config,
		threshold:    threshold,
	}, nil
}

// CheckBucketUsage checks the current usage of the bucket. If no primary bucket exists, it uses or creates one.
func (sm *StorageManager) CheckBucketUsage() (float64, error) {
	// Try to get the primary bucket
	fmt.Println("Checking bucket usage...", sm.bucketName)
	primaryBucket, err := models.BucketByIsPrimary(sm.ctx, sm.DB, true)
	if err != nil {
		if err == sql.ErrNoRows {
			// No primary bucket exists, check if the configured bucket exists in Spaces
			fmt.Println("No primary bucket found, checking if configured bucket exists...", sm.bucketName)

			fmt.Println("Using key:", sm.uploadConfig.AccessKeyID)

			// Check if the bucket exists and we own it
			_, err := sm.s3Client.HeadBucket(&s3.HeadBucketInput{
				Bucket:              aws.String(sm.bucketName),
				ExpectedBucketOwner: aws.String(sm.uploadConfig.AccessKeyID),
			})
			if err != nil {
				// If the bucket doesn't exist or we don't own it, create it
				if awsErr, ok := err.(awserr.Error); ok && awsErr.Code() == s3.ErrCodeNoSuchBucket || awsErr.Code() == "NotFound" {
					fmt.Printf("Bucket %s does not exist or is not owned by us, creating it...\n", sm.bucketName)
					_, err := sm.CreateNewBucket(sm.bucketName)
					if err != nil && !strings.Contains(err.Error(), "already exists") {
						return 0, fmt.Errorf("failed to create bucket %s: %w", sm.bucketName, err)
					}
				} else {
					return 0, fmt.Errorf("failed to check if bucket exists: %w", err)
				}
			} else {
				fmt.Printf("Bucket %s exists and is owned by us, proceeding...\n", sm.bucketName)
			}

			// Now add the bucket to the database as the primary bucket
			err = sm.addBucketToDB(sm.bucketName, true)
			if err != nil {
				return 0, fmt.Errorf("failed to add bucket to database: %w", err)
			}

			// After creating or verifying, we can safely return 0 usage
			return 0, nil
		}
		return 0, fmt.Errorf("failed to get primary bucket: %w", err)
	}

	// Proceed to calculate usage as before
	totalSize := primaryBucket.TotalSize
	if totalSize == 0 {
		return 0, nil
	}

	usagePercentage := float64(totalSize) / float64(DigitalOceanBucketMaxSize) * 100
	return usagePercentage, nil
}

// generateNextBucketName generates the next bucket name based on the current bucket name
func (sm *StorageManager) generateNextBucketName() string {
	bucketNameParts := strings.Split(sm.bucketName, "-")
	var newBucketName string
	if len(bucketNameParts) > 1 {
		lastPart := bucketNameParts[len(bucketNameParts)-1]
		lastNumber, err := strconv.Atoi(lastPart)
		if err != nil {
			newBucketName = fmt.Sprintf("%s-1", sm.bucketName)
		} else {
			newBucketName = fmt.Sprintf("%s-%d", strings.Join(bucketNameParts[:len(bucketNameParts)-1], "-"), lastNumber+1)
		}
	} else {
		newBucketName = fmt.Sprintf("%s-1", sm.bucketName)
	}
	return newBucketName
}

// CreateNewBucket creates a new bucket and switches the system over to use it
func (sm *StorageManager) CreateNewBucket(newBucketName string) (string, error) {

	// Create a new Space (bucket) in DigitalOcean
	input := &s3.CreateBucketInput{
		Bucket: aws.String(newBucketName),
		ACL:    aws.String("public-read"),
	}

	_, err := sm.s3Client.CreateBucket(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeBucketAlreadyExists:
				return "", fmt.Errorf("bucket %s already exists", newBucketName)
			case s3.ErrCodeBucketAlreadyOwnedByYou:
				fmt.Printf("Bucket %s already exists and is owned by you, proceeding...\n", newBucketName)
			default:
				return "", fmt.Errorf("failed to create new bucket: %w", err)
			}
		} else {
			return "", fmt.Errorf("failed to create new bucket: %w", err)
		}
	}

	// Wait for the bucket to be created and available
	err = sm.s3Client.WaitUntilBucketExists(&s3.HeadBucketInput{
		Bucket: aws.String(newBucketName),
	})
	if err != nil {
		return "", fmt.Errorf("error waiting for bucket to be created: %w", err)
	}

	// Update the database with the new bucket as primary
	err = sm.updateBucketInDB(newBucketName)
	if err != nil {
		return "", fmt.Errorf("failed to update database with new bucket: %w", err)
	}

	sm.bucketName = newBucketName
	return newBucketName, nil
}

// addBucketToDB adds a new bucket to the database, optionally setting it as primary
func (sm *StorageManager) addBucketToDB(bucketName string, isPrimary bool) error {
	// Start a transaction
	tx, err := sm.DB.BeginTx(sm.ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	// Ensure the transaction is rolled back if something goes wrong
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
		}
	}()

	// Check if the bucket already exists
	existingBucket, err := models.BucketByBucketName(sm.ctx, tx, bucketName)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("failed to check for existing bucket: %w", err)
	}
	if existingBucket != nil {
		// Bucket already exists, no need to insert again
		return nil
	}

	// If setting as primary, mark existing primary bucket as non-primary
	if isPrimary {
		primaryBucket, err := models.BucketByIsPrimary(sm.ctx, tx, true)
		if err != nil && err != sql.ErrNoRows {
			return fmt.Errorf("failed to get primary bucket: %w", err)
		}
		if err == nil {
			primaryBucket.IsPrimary = false
			err = primaryBucket.Save(sm.ctx, tx)
			if err != nil {
				return fmt.Errorf("failed to update current bucket status: %w", err)
			}
		}
	}

	// Insert the new bucket
	newBucket := &models.Bucket{
		BucketName: bucketName,
		Region:     types.NewNullString(sm.uploadConfig.Region),
		IsPrimary:  isPrimary,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	err = newBucket.Save(sm.ctx, tx)
	if err != nil {
		return fmt.Errorf("failed to insert new bucket: %w", err)
	}

	// Commit the transaction after successful updates
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// updateBucketInDB updates the bucket information in the database and sets the new bucket as primary
func (sm *StorageManager) updateBucketInDB(newBucketName string) error {
	// Start a transaction
	tx, err := sm.DB.BeginTx(sm.ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	// Ensure the transaction is rolled back if something goes wrong
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	// Try to fetch the current primary bucket from the DB
	primaryBucket, err := models.BucketByIsPrimary(sm.ctx, tx, true)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("failed to get primary bucket: %w", err)
	}

	// If a primary bucket exists, mark it as non-primary
	if primaryBucket != nil && err != sql.ErrNoRows {
		primaryBucket.IsPrimary = false
		err = primaryBucket.Save(sm.ctx, tx)
		if err != nil {
			return fmt.Errorf("failed to update current bucket status: %w", err)
		}
	}

	// Insert the new bucket as the primary bucket
	newBucket := &models.Bucket{
		BucketName: newBucketName,
		Region:     types.NewNullString(sm.uploadConfig.Region),
		IsPrimary:  true,
		UpdatedAt:  time.Now(),
	}
	err = newBucket.Save(sm.ctx, tx)
	if err != nil {
		return fmt.Errorf("failed to insert new bucket: %w", err)
	}

	// Commit the transaction after successful updates
	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// SwitchBucketIfNeeded checks the current bucket usage and switches to a new bucket if usage exceeds the threshold
func (sm *StorageManager) SwitchBucketIfNeeded() error {
	usage, err := sm.CheckBucketUsage()
	if err != nil {
		return fmt.Errorf("failed to check bucket usage: %w", err)
	}

	if usage >= sm.threshold {
		newBucketName := sm.generateNextBucketName()
		_, err := sm.CreateNewBucket(newBucketName)
		if err != nil {
			return fmt.Errorf("failed to create new bucket: %w", err)
		}
	}

	return nil
}

// GetCurrentPrimaryBucket fetches the current primary bucket from the database
func (sm *StorageManager) GetCurrentPrimaryBucket() (string, error) {
	primaryBucket, err := models.BucketByIsPrimary(sm.ctx, sm.DB, true)
	if err != nil {
		return "", fmt.Errorf("failed to get current primary bucket: %w", err)
	}
	return primaryBucket.BucketName, nil
}
