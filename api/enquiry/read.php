<?php
// Required headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Include database and object files
include_once '../config/database.php';
include_once '../models/enquiry.php';

// Initialize database and enquiry object
$database = new Database();
$db = $database->getConnection();

// Initialize enquiry object
$enquiry = new Enquiry($db);

// Query enquiries
$stmt = $enquiry->read();
$num = $stmt->rowCount();

// Check if more than 0 record found
if($num > 0) {
    // Enquiries array
    $enquiries_arr = array();
    $enquiries_arr["records"] = array();

    // Retrieve table contents
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Extract row
        extract($row);

        $enquiry_item = array(
            "id" => $id,
            "name" => $name,
            "mobile" => $mobile,
            "callback_time" => $callback_time,
            "remark" => $remark,
            "package_name" => $package_name,
            "total_amount" => $total_amount,
            "paid_amount" => $paid_amount,
            "status" => $status,
            "status_color_code" => $status_color_code,
            "status_type" => $status_type,
            "created_at" => $created_at,
            "updated_at" => $updated_at
        );

        array_push($enquiries_arr["records"], $enquiry_item);
    }

    // Set response code - 200 OK
    http_response_code(200);

    // Show enquiries data in JSON format
    echo json_encode($enquiries_arr);
} else {
    // Set response code - 404 Not found
    http_response_code(200);

    // Tell the user no enquiries found
    echo json_encode(
        array("records" => array(), "message" => "No enquiries found.")
    );
}
?>
