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

// Make sure id is not empty
if(!empty($data->id)) {
    // Set ID property of enquiry to be updated
    $enquiry->id = $data->id;
    
    // Set enquiry property values
    $enquiry->name = property_exists($data, 'name') ? $data->name : $enquiry->name;
    $enquiry->mobile = property_exists($data, 'mobile') ? $data->mobile : $enquiry->mobile;
    $enquiry->callback_time = property_exists($data, 'callback_time') ? $data->callback_time : $enquiry->callback_time;
    $enquiry->remark = property_exists($data, 'remark') ? $data->remark : $enquiry->remark;
    $enquiry->package_name = property_exists($data, 'package_name') ? $data->package_name : $enquiry->package_name;
    $enquiry->total_amount = property_exists($data, 'total_amount') ? $data->total_amount : $enquiry->total_amount;
    $enquiry->paid_amount = property_exists($data, 'paid_amount') ? $data->paid_amount : $enquiry->paid_amount;
    $enquiry->status = property_exists($data, 'status') ? $data->status : $enquiry->status;
    $enquiry->status_color_code = property_exists($data, 'status_color_code') ? $data->status_color_code : $enquiry->status_color_code;
    $enquiry->status_type = property_exists($data, 'status_type') ? $data->status_type : $enquiry->status_type;

    // Update the enquiry
    if($enquiry->update()) {
        // Set response code - 200 ok
        http_response_code(200);

        // Tell the user
        echo json_encode(array("message" => "Enquiry was updated."));
    } else {
        // Set response code - 503 service unavailable
        http_response_code(503);

        // Tell the user
        echo json_encode(array("message" => "Unable to update enquiry."));
    }
} else {
    // Set response code - 400 bad request
    http_response_code(400);

    // Tell the user
    echo json_encode(array("message" => "Unable to update enquiry. ID is required."));
}
?>
