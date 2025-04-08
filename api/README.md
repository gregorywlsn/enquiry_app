# Enquiry App API

This is a RESTful API for the Enquiry App built with PHP and MySQL.

## Database Setup

1. Import the SQL file located at `database/enquiry_app.sql` into your MySQL server:
   ```
   mysql -u username -p < database/enquiry_app.sql
   ```
   
2. Update the database credentials in `config/database.php` if needed.

## API Endpoints

### Enquiries

#### Get all enquiries
```
GET /api/enquiry/read.php
```

#### Get a single enquiry
```
GET /api/enquiry/read_one.php?id=1
```

#### Create a new enquiry
```
POST /api/enquiry/create.php
```
Request body:
```json
{
  "name": "John Doe",
  "mobile": "1234567890",
  "callback_time": "2025-04-05 14:30:00",
  "remark": "Interested in premium package",
  "package_name": "Premium Package",
  "total_amount": "2500",
  "paid_amount": "1000",
  "status": "Callback",
  "status_color_code": "#FFA500",
  "status_type": "timer"
}
```

#### Update an enquiry
```
POST /api/enquiry/update.php
```
Request body:
```json
{
  "id": "1",
  "name": "John Doe",
  "mobile": "1234567890",
  "callback_time": "2025-04-05 15:30:00",
  "remark": "Very interested in premium package",
  "package_name": "Premium Package",
  "total_amount": "2500",
  "paid_amount": "1500",
  "status": "Interested",
  "status_color_code": "#008000",
  "status_type": "default"
}
```

#### Update enquiry status
```
POST /api/enquiry/update_status.php
```
Request body:
```json
{
  "id": "1",
  "status": "Interested",
  "status_color_code": "#008000",
  "status_type": "default"
}
```

#### Delete an enquiry
```
POST /api/enquiry/delete.php
```
Request body:
```json
{
  "id": "1"
}
```

## Integration with Flutter App

To integrate this API with the Flutter app:

1. Update the base URL in the Flutter app's ApiService class:
   ```dart
   _apiService = ApiService(baseUrl: 'http://your-server-url.com/api');
   ```

2. Make sure the Flutter app has the http package installed:
   ```
   flutter pub add http
   ```

3. The API endpoints match the methods in the Flutter app's ApiService class, so no additional changes should be needed.

## MySQL Database Schema

The `enquiries` table has the following columns:

| Column Name      | Data Type      | Description                                |
|------------------|-----------------|--------------------------------------------|
| id               | int(11)         | Primary key, auto-increment                |
| name             | varchar(255)    | Name of the enquiry contact                |
| mobile           | varchar(20)     | Mobile number                              |
| callback_time    | datetime        | Scheduled callback time (nullable)         |
| remark           | text            | Additional notes or remarks                |
| package_name     | varchar(255)    | Name of the package                        |
| total_amount     | decimal(10,2)   | Total amount for the package               |
| paid_amount      | decimal(10,2)   | Amount already paid                        |
| status           | varchar(50)     | Current status (e.g., "Callback")          |
| status_color_code| varchar(20)     | Hex color code for the status              |
| status_type      | varchar(20)     | Type of status (e.g., "timer", "default")  |
| created_at       | datetime        | Record creation timestamp                  |
| updated_at       | datetime        | Record last update timestamp               |
