package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
	_ "github.com/go-sql-driver/mysql"
)

var dsn = "anis:anisynov@tcp(100.42.185.129:3306)/trackerloldb"

type User struct {
	Email string `json:"email"`
	Mdp   string `json:"mdp"`
}

func main() {
	r := gin.Default()
	r.Use(cors.Default())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"POST", "GET", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	r.POST("/register", handleUserRegister)
	r.POST("/login", handleUserLogin)
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Erreur au démarrage du serveur : %v", err)
	}
	db, _ := bdd()
	defer db.Close()
	//insertUser(db, "tom", "tesst@test.com", "2023-10-01 12:00:00", sql.NullInt64{Int64: 123456, Valid: true})
	openbdd()
}

func bdd() (*sql.DB, error) {
	return sql.Open("mysql", dsn)
}

func openbdd() {
	db, err := bdd()
	if err != nil {
		log.Fatalf("Erreur lors de la connexion à la base de données : %v", err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatalf("Impossible de se connecter à la base : %v", err)
	}

	rows, err := db.Query("SHOW TABLES")
	if err != nil {
		log.Fatalf("Erreur lors de la requête : %v", err)
	}
	defer rows.Close()

	var tableName string
	fmt.Println("Tables dans la base :")
	for rows.Next() {
		if err := rows.Scan(&tableName); err != nil {
			log.Println("Erreur lors de la lecture de la ligne :", err)
		}
		fmt.Println(" -", tableName)
	}

	fmt.Println("\nDonnées de la table " + tableName + ":")
	rows, err = db.Query("SELECT * FROM users")
	if err != nil {
		log.Fatalf("Erreur lors de la requête sur 'joueurs' : %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var id int
		var name string
		var email string
		var time_create string
		var mdp string
		var IdRiot sql.NullInt64
		if err := rows.Scan(&id, &name, &email, &time_create, &mdp, &IdRiot); err != nil {
			log.Println("Erreur lors de la lecture de la ligne :", err)
		}
		mdpValue := "NULL"
		if mdp != "" {
			mdpValue = mdp
		}
		IdRiotValue := "NULL"
		if IdRiot.Valid {
			IdRiotValue = fmt.Sprintf("%d", IdRiot.Int64)
		}
		fmt.Printf("ID: %d, Nom: %s, Email: %s, Time_create: %s, mdp: %s, IdRiot: %s\n", id, name, email, time_create, mdpValue, IdRiotValue)
	}

	if err := rows.Err(); err != nil {
		log.Fatalf("Erreur lors du traitement des lignes : %v", err)
	}
}

func insertUser(db *sql.DB, email string, mdp string) error {
	query := "INSERT INTO users (email, mdp) VALUES (?, ?)"
	_, err := db.Exec(query, email, mdp)
	if err != nil {
		if mysqlErr, ok := err.(*mysql.MySQLError); ok && mysqlErr.Number == 1062 {
			return fmt.Errorf("L'email %s est déjà utilisé", email)
		}
		return fmt.Errorf("Erreur lors de l'insertion de l'utilisateur : %v", err)
	}
	return nil
}

func deleteUser(db *sql.DB, email string) error {
	query := "DELETE FROM users WHERE email = ?"
	_, err := db.Exec(query, email)
	if err != nil {
		return fmt.Errorf("Erreur lors de la suppression de l'utilisateur : %v", err)
	}
	return nil
}

func handleUserRegister(apagnan *gin.Context) {
	var user User
	if err := apagnan.ShouldBindJSON(&user); err != nil {
		apagnan.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input1"})
		return
	}

	db, err := bdd()
	if err != nil {
		apagnan.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection error"})
		return
	}
	defer db.Close()

	err = insertUser(db, user.Email, user.Mdp)
	if err != nil {
		apagnan.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	apagnan.JSON(http.StatusOK, gin.H{"message": "User registered successfully"})
}

func handleUserLogin(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input2"})
		return
	}

	db, err := bdd()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection error"})
		return
	}
	defer db.Close()

	query := "SELECT email, mdp FROM users WHERE email = ? AND mdp = ?"
	row := db.QueryRow(query, user.Email, user.Mdp)

	err = row.Scan(&user.Email, &user.Mdp)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database query error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Login successful"})
}
