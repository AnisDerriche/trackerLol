package main

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/go-sql-driver/mysql"
	_ "github.com/go-sql-driver/mysql"
)

var dsn = "anis:anisynov@tcp(100.42.185.129:3306)/trackerloldb"

func main() {
	db, _ := bdd()
	defer db.Close()
	insertUser(db, "tom", "tesst@test.com", "2023-10-01 12:00:00", sql.NullInt64{Int64: 123456, Valid: true})
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
		var mdp sql.NullInt64
		if err := rows.Scan(&id, &name, &email, &time_create, &mdp); err != nil {
			log.Println("Erreur lors de la lecture de la ligne :", err)
		}
		mdpValue := "NULL"
		if mdp.Valid {
			mdpValue = fmt.Sprintf("%d", mdp.Int64)
		}
		fmt.Printf("ID: %d, Nom: %s, Email: %s, Time_create: %s, mdp: %s\n", id, name, email, time_create, mdpValue)
	}

	if err := rows.Err(); err != nil {
		log.Fatalf("Erreur lors du traitement des lignes : %v", err)
	}
}

func insertUser(db *sql.DB, name string, email string, time_create string, mdp sql.NullInt64) error {
	query := "INSERT INTO users (name, email, time_create, mdp) VALUES (?, ?, ?, ?)"
	_, err := db.Exec(query, name, email, time_create, mdp)
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
