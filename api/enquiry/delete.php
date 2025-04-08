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
    // Set ID property of enquiry to be deleted
    $enquiry->id = $data->id;

    // Delete the enquiry
    if($enquiry->delete()) {
        // Set response code - 200 ok
        http_response_code(200);

        // Tell the user
        echo json_encode(array("message" => "Enquiry was deleted."));
    } else {
        // Set response code - 503 service unavailable
        http_response_code(503);

        // Tell the user
        echo json_encode(array("message" => "Unable to delete enquiry."));
    }
} else {
    // Set response code - 400 bad request
    http_response_code(400);

    // Tell the user
    echo json_encode(array("message" => "Unable to delete enquiry. ID is required."));
}
?>
