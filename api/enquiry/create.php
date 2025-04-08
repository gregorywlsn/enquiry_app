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

// Make sure data is not empty
if(
    !empty($data->name) &&
    !empty($data->mobile)
) {
    // Set enquiry property values
    $enquiry->name = $data->name;
    $enquiry->mobile = $data->mobile;
    $enquiry->callback_time = property_exists($data, 'callback_time') ? $data->callback_time : null;
    $enquiry->remark = property_exists($data, 'remark') ? $data->remark : '';
    $enquiry->package_name = property_exists($data, 'package_name') ? $data->package_name : '';
    $enquiry->total_amount = property_exists($data, 'total_amount') ? $data->total_amount : '0';
    $enquiry->paid_amount = property_exists($data, 'paid_amount') ? $data->paid_amount : '0';
    $enquiry->status = property_exists($data, 'status') ? $data->status : 'New';
    $enquiry->status_color_code = property_exists($data, 'status_color_code') ? $data->status_color_code : '#FFA500';
    $enquiry->status_type = property_exists($data, 'status_type') ? $data->status_type : 'default';

    // Create the enquiry
    if($enquiry->create()) {
        // Set response code - 201 created
        http_response_code(201);

        // Tell the user
        echo json_encode(array(
            "message" => "Enquiry was created.",
            "id" => $enquiry->id
        ));
    } else {
        // Set response code - 503 service unavailable
        http_response_code(503);

        // Tell the user
        echo json_encode(array("message" => "Unable to create enquiry."));
    }
} else {
    // Set response code - 400 bad request
    http_response_code(400);

    // Tell the user
    echo json_encode(array("message" => "Unable to create enquiry. Data is incomplete."));
}
?>
