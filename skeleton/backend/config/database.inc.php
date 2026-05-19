<?php 
  class Database {
    private $pdo;

    public function __construct($host, $db, $user, $password) {
        $dsn = "mysql:host=$host;charset=utf8mb4";
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

    public function query($query, $params = []) {
        $stmt = $this->pdo->prepare($query);
        $stmt->execute($params);
        return $stmt;
    }

    public function fetchAll($query, $params = []) {
        return $this->query($query, $params)->fetchAll();
    }

    public function fetchOne($query, $params = []) {
        $res = $this->query($query, $params)->fetch();
        return $res ? $res : []; 
    }
  }

  // funzioni funzionali ;) ----------------------------------
  
  function standardQuery(Database $db, $query, $params = []) {
    try {
      return $db->fetchAll($query, $params);
    } catch (PDOException $th) {
      http_response_code(500);
      error_log("errore: " . $th->getMessage());
      echo "errore di connessione con il db";
      exit;
    }
  }

  function getDB(){
    $host = "localhost";
    $db   = "gestione_fotocopiatrici_buzzi";
    $user = "root";
    $pass = "";

    return new Database($host, $db, $user, $pass);
  }
?>