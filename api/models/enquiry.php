<?php
class Enquiry {
    // Database connection and table name
    private $conn;
    private $table_name = "enquiries";

    // Object properties
    public $id;
    public $name;
    public $mobile;
    public $callback_time;
    public $remark;
    public $package_name;
    public $total_amount;
    public $paid_amount;
    public $status;
    public $status_color_code;
    public $status_type;
    public $created_at;
    public $updated_at;

    // Constructor with database connection
    public function __construct($db) {
        $this->conn = $db;
    }

    // Read all enquiries
    public function read() {
        // Query to select all enquiries
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY created_at DESC";
        
        // Prepare statement
        $stmt = $this->conn->prepare($query);
        
        // Execute query
        $stmt->execute();
        
        return $stmt;
    }

    // Read single enquiry
    public function readOne() {
        // Query to read single record
        $query = "SELECT * FROM " . $this->table_name . " WHERE id = ? LIMIT 0,1";
        
        // Prepare statement
        $stmt = $this->conn->prepare($query);
        
        // Bind ID parameter
        $stmt->bindParam(1, $this->id);
        
        // Execute query
        $stmt->execute();
        
        // Get retrieved row
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Set properties
        if($row) {
            $this->id = $row['id'];
            $this->name = $row['name'];
            $this->mobile = $row['mobile'];
            $this->callback_time = $row['callback_time'];
            $this->remark = $row['remark'];
            $this->package_name = $row['package_name'];
            $this->total_amount = $row['total_amount'];
            $this->paid_amount = $row['paid_amount'];
            $this->status = $row['status'];
            $this->status_color_code = $row['status_color_code'];
            $this->status_type = $row['status_type'];
            $this->created_at = $row['created_at'];
            $this->updated_at = $row['updated_at'];
            return true;
        }
        
        return false;
    }

    // Create enquiry
    public function create() {
        // Query to insert record
        $query = "INSERT INTO " . $this->table_name . "
                  SET 
                    name=:name, 
                    mobile=:mobile, 
                    callback_time=:callback_time, 
                    remark=:remark, 
                    package_name=:package_name, 
                    total_amount=:total_amount, 
                    paid_amount=:paid_amount, 
                    status=:status, 
                    status_color_code=:status_color_code, 
                    status_type=:status_type, 
                    created_at=:created_at, 
                    updated_at=:updated_at";
        
        // Prepare statement
        $stmt = $this->conn->prepare($query);
        
        // Sanitize input
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->mobile = htmlspecialchars(strip_tags($this->mobile));
        $this->callback_time = htmlspecialchars(strip_tags($this->callback_time));
        $this->remark = htmlspecialchars(strip_tags($this->remark));
        $this->package_name = htmlspecialchars(strip_tags($this->package_name));
        $this->total_amount = htmlspecialchars(strip_tags($this->total_amount));
        $this->paid_amount = htmlspecialchars(strip_tags($this->paid_amount));
        $this->status = htmlspecialchars(strip_tags($this->status));
        $this->status_color_code = htmlspecialchars(strip_tags($this->status_color_code));
        $this->status_type = htmlspecialchars(strip_tags($this->status_type));
        
        // Set timestamps
        $this->created_at = date('Y-m-d H:i:s');
        $this->updated_at = date('Y-m-d H:i:s');
        
        // Bind values
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":mobile", $this->mobile);
        $stmt->bindParam(":callback_time", $this->callback_time);
        $stmt->bindParam(":remark", $this->remark);
        $stmt->bindParam(":package_name", $this->package_name);
        $stmt->bindParam(":total_amount", $this->total_amount);
        $stmt->bindParam(":paid_amount", $this->paid_amount);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":status_color_code", $this->status_color_code);
        $stmt->bindParam(":status_type", $this->status_type);
        $stmt->bindParam(":created_at", $this->created_at);
        $stmt->bindParam(":updated_at", $this->updated_at);
        
        // Execute query
        if($stmt->execute()) {
            $this->id = $this->conn->lastInsertId();
            return true;
        }
        
        return false;
    }

    // Update enquiry
    public function update() {
        // Query to update record
        $query = "UPDATE " . $this->table_name . "
                  SET 
                    name=:name, 
                    mobile=:mobile, 
                    callback_time=:callback_time, 
                    remark=:remark, 
                    package_name=:package_name, 
                    total_amount=:total_amount, 
                    paid_amount=:paid_amount, 
                    status=:status, 
                    status_color_code=:status_color_code, 
                    status_type=:status_type, 
                    updated_at=:updated_at
                  WHERE 
                    id=:id";
        
        // Prepare statement
        $stmt = $this->conn->prepare($query);
        
        // Sanitize input
        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->name = htmlspecialchars(strip_tags($this->name));
        $this->mobile = htmlspecialchars(strip_tags($this->mobile));
        $this->callback_time = htmlspecialchars(strip_tags($this->callback_time));
        $this->remark = htmlspecialchars(strip_tags($this->remark));
        $this->package_name = htmlspecialchars(strip_tags($this->package_name));
        $this->total_amount = htmlspecialchars(strip_tags($this->total_amount));
        $this->paid_amount = htmlspecialchars(strip_tags($this->paid_amount));
        $this->status = htmlspecialchars(strip_tags($this->status));
        $this->status_color_code = htmlspecialchars(strip_tags($this->status_color_code));
        $this->status_type = htmlspecialchars(strip_tags($this->status_type));
        
        // Set updated timestamp
        $this->updated_at = date('Y-m-d H:i:s');
        
        // Bind values
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":mobile", $this->mobile);
        $stmt->bindParam(":callback_time", $this->callback_time);
        $stmt->bindParam(":remark", $this->remark);
        $stmt->bindParam(":package_name", $this->package_name);
        $stmt->bindParam(":total_amount", $this->total_amount);
        $stmt->bindParam(":paid_amount", $this->paid_amount);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":status_color_code", $this->status_color_code);
        $stmt->bindParam(":status_type", $this->status_type);
        $stmt->bindParam(":updated_at", $this->updated_at);
        
        // Execute query
        if($stmt->execute()) {
            return true;
        }
        
        return false;
    }

    // Delete enquiry
    public function delete() {
        // Query to delete record
        $query = "DELETE FROM " . $this->table_name . " WHERE id = ?";
        
        // Prepare statement
        $stmt = $this->conn->prepare($query);
        
        // Sanitize input
        $this->id = htmlspecialchars(strip_tags($this->id));
        
        // Bind ID parameter
        $stmt->bindParam(1, $this->id);
        
        // Execute query
        if($stmt->execute()) {
            return true;
        }
        
        return false;
    }

    // Update status only
    public function updateStatus() {
        // Query to update status
        $query = "UPDATE " . $this->table_name . "
                  SET 
                    status=:status, 
                    callback_time=:callback_time, 
                    status_color_code=:status_color_code, 
                    status_type=:status_type, 
                    updated_at=:updated_at
                  WHERE 
                    id=:id";
        
        // Prepare statement
        $stmt = $this->conn->prepare($query);
        
        // Sanitize input
        $this->id = htmlspecialchars(strip_tags($this->id));
        $this->status = htmlspecialchars(strip_tags($this->status));
        $this->callback_time = htmlspecialchars(strip_tags($this->callback_time));
        $this->status_color_code = htmlspecialchars(strip_tags($this->status_color_code));
        $this->status_type = htmlspecialchars(strip_tags($this->status_type));
        
        // Set updated timestamp
        $this->updated_at = date('Y-m-d H:i:s');
        
        // Bind values
        $stmt->bindParam(":id", $this->id);
        $stmt->bindParam(":status", $this->status);
        $stmt->bindParam(":callback_time", $this->callback_time);
        $stmt->bindParam(":status_color_code", $this->status_color_code);
        $stmt->bindParam(":status_type", $this->status_type);
        $stmt->bindParam(":updated_at", $this->updated_at);
        
        // Execute query
        if($stmt->execute()) {
            return true;
        }
        
        return false;
    }
}
?>
