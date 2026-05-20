<?php 
  class Database {
    private $pdo;

    public function __construct($host, $port, $db, $user, $password) {
        $dsn = "mysql:host=$host;port=$port;charset=utf8mb4";
        $this->pdo = new PDO($dsn, $user, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::MYSQL_ATTR_USE_BUFFERED_QUERY => true 
        ]);
        $this->build($db);
    }

    private function build($db){

      $this->pdo->exec("CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
      $this->pdo->exec("USE `$db` ");
      $check = $this->pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$db'")->fetchColumn();;
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
        try {
          $this->sql($query, $params);
          return true;
        } catch (PDOException $e) {
          return false;
        }
    }

    public function query($query, $params = []) {
        return $this->sql($query, $params)->fetchAll();
    }

    private static function getDB(){
      
    }
  }

  // funzioni funzionali ;) ----------------------------------
  
  class DbUtils {
      
      public static function getDB(){
        $host = "localhost";
        $db   = "gestione_fotocopiatrici_buzzi";
        $user = "root";
        $pass = "";
        $port = 3306;

        return new Database($host, $port, $db, $user, $pass);
      }

      public static function standardQuery($query, $params = [], Database $db = null) {
        $database = $db ?? self::getDB();
        try {
          return $database->query($query, $params);
        } catch (Exception $th) {
          error_log("StandardQuery Error: " . $th->getMessage());
          http_response_code(500);
          exit;
        }
      }

      public static function standardExec($query, $params = [], Database $db = null) {
        $database = $db ?? self::getDB();
        $success = $database->execute($query, $params);

        if (!$success){
          error_log("StandardExec Error: Query fallita");
          http_response_code(500);
          exit;
        }
      }
  }
?>