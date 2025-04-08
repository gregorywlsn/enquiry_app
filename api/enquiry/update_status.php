<?php
// Required headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Include database and object files
include_once '../config/database.php';
include_once '../models/enquiry.php';

// Get database connection
$database = new Database();
$db = $database->getConnection();

// Initialize enquiry object
$enquiry = new Enquiry($db);

// Get posted data
$data = json_decode(file_get_contents("php://input"));

// Make sure id and status are not empty
if(!empty($data->id) && !empty($data->status)) {
    // Set ID property of enquiry to be updated
    $enquiry->id = $data->id;
    
    // Set status properties
    $enquiry->status = $data->status;
    $enquiry->callback_time = property_exists($data, 'callback_time') ? $data->callback_time : null;
    $enquiry->status_color_code = property_exists($data, 'status_color_code') ? $data->status_color_code : '#FFA500';
    $enquiry->status_type = property_exists($data, 'status_type') ? $data->status_type : 'default';

    // Update the enquiry status
    if($enquiry->updateStatus()) {
        // Set response code - 200 ok
        http_response_code(200);

        // Tell the user
        echo json_encode(array("message" => "Enquiry status was updated."));
    } else {
        // Set response code - 503 service unavailable
        http_response_code(503);

        // Tell the user
        echo json_encode(array("message" => "Unable to update enquiry status."));
    }
} else {
    // Set response code - 400 bad request
    http_response_code(400);

    // Tell the user
    echo json_encode(array("message" => "Unable to update enquiry status. ID and status are required."));
}
?>
