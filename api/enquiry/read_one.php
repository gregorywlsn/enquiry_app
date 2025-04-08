<?php
// Required headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: access");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Credentials: true");
header("Content-Type: application/json");

// Include database and object files
include_once '../config/database.php';
include_once '../models/enquiry.php';

// Get database connection
$database = new Database();
$db = $database->getConnection();

// Initialize enquiry object
$enquiry = new Enquiry($db);

// Set ID property of enquiry to be read
$enquiry->id = isset($_GET['id']) ? $_GET['id'] : die();

// Read the details of enquiry
$enquiry->readOne();

// Check if enquiry exists
if($enquiry->name != null) {
    // Create array
    $enquiry_arr = array(
        "id" => $enquiry->id,
        "name" => $enquiry->name,
        "mobile" => $enquiry->mobile,
        "callback_time" => $enquiry->callback_time,
        "remark" => $enquiry->remark,
        "package_name" => $enquiry->package_name,
        "total_amount" => $enquiry->total_amount,
        "paid_amount" => $enquiry->paid_amount,
        "status" => $enquiry->status,
        "status_color_code" => $enquiry->status_color_code,
        "status_type" => $enquiry->status_type,
        "created_at" => $enquiry->created_at,
        "updated_at" => $enquiry->updated_at
    );

    // Set response code - 200 OK
    http_response_code(200);

    // Make it json format
    echo json_encode($enquiry_arr);
} else {
    // Set response code - 404 Not found
    http_response_code(404);

    // Tell the user enquiry does not exist
    echo json_encode(array("message" => "Enquiry does not exist."));
}
?>
