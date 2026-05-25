<?php 
class Database {
  private $pdo; 
  public function __construct($host, $port, $db, $user, $password) { 
    $dsn = "mysql:host=$host;port=$port;charset=utf8mb4";
    try { 
      $this->pdo = new PDO($dsn, $user, $password, [ 
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, 
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC 
      ]); 
      $this->build($db); 
    } catch (PDOException $e) { http_response_code(500); exit; } 
  } 
  private function build($db){ 
    $this->pdo->exec("CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $this->pdo->exec("USE `$db` "); 
    $check = $this->pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$db'")->fetchColumn();
    $path = __DIR__ . "/db.sql"; 
    if (file_exists($path) && !$check) { 
      $sql = trim(file_get_contents($path)); 
      if (!empty($sql)) { 
        $this->pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, 1); 
        $this->pdo->exec($sql); 
      } 
    } 
  } 
  public function sql($query, $params = []) { 
    $stmt = $this->pdo->prepare($query); 
    $stmt->execute($params); 
    return $stmt; 
  } 
  public function execute($query, $params = []) { 
    try { $this->sql($query, $params); return true; } 
    catch (PDOException $e) { return false; } 
  } 
  public function query($query, $params = []) { 
    return $this->sql($query, $params)->fetchAll(); 
  } 
} 
class DbUtils { 
  private static $con = null;
  public static function getDB(){
    if(self::$con === null) self::$con = new Database("host", "port", "database", "user", "password");    
    return self::$con;
  } 
  public static function query($q, $p = [], $db = null) { 
    $d = $db ?? self::getDB(); 
    try { return $d->query($q, $p); } 
    catch (Exception $e) { http_response_code(500); echo json_encode(["SQLError" => $e->getMessage()]); exit; } 
  } 
  public static function execute($q, $p = [], $db = null) {
    $d = $db ?? self::getDB(); 
    return $d->execute($q, $p);
  } 
}
?>
