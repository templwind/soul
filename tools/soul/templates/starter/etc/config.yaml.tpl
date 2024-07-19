DefaultDataDir: data
DatabaseFileName: data.db
RunMigrations: true
MigrationsPath: db/migrations
Auth:
  TokenSecret: "${TOKEN_SECRET}"
  TokenDuration: 24h
Setup:
  DefaultAdmin:
    Name: ${DEFAULT_ADMIN_NAME}
    Username: ${DEFAULT_ADMIN_USERNAME}
    Email: ${DEFAULT_ADMIN_EMAIL}
    Password: "${DEFAULT_ADMIN_PASSWORD}"
  TestUser:
    Name: ${TEST_USER_NAME}
    Username: ${TEST_USER_USERNAME}
    Email: ${TEST_USER_EMAIL}
    Password: "${TEST_USER_PASSWORD}"