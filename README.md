# OPAC Prolog Setup Manual (Windows)

## Instructor Quick Steps (XAMPP/MariaDB ODBC Setup)

Good day, ma'am! For this OPAC project, the Prolog app connects through ODBC and requires a System DSN named opac_db. The following are the steps to ensure that it runs effectively on your end:

1. Ensure XAMPP MySQL is running.
2. Create database opac_db in phpMyAdmin.
3. Import opac_db.sql into opac_db.
4. Install a 64-bit ODBC driver:
   - MariaDB Connector/ODBC 64-bit (recommended), or
   - MySQL Connector/ODBC 8.x 64-bit.
   - Preferably, you may install from this link: https://dev.mysql.com/downloads/connector/odbc/
5. Open 64-bit ODBC Administrator:
   - C:\\Windows\\System32\\odbcad32.exe
6. Go to System DSN, click Add, choose the installed MariaDB/MySQL ODBC driver.
    - Typically, it is named "MySQL ODBC 9.6 Unicode Driver"
7. Set DSN values:
   - Data Source Name: opac_db
   - Server: 127.0.0.1
   - Port: 3306
   - User: root
   - Password: (XAMPP default is usually blank unless configured)
   - Database: opac_db
8. Click Test Connection, then Save.
9. Run the app:
   - "C:\\Program Files\\swipl\\bin\\swipl.exe" -q -s app.pl

If DSN opac_db is set correctly, SQL sync will work at startup and save.

If the following steps above do not work, kindly check the full manual below:

This guide is a complete, beginner-friendly setup manual for running this OPAC project on a Windows PC.

It covers:
- SWI-Prolog installation
- MariaDB/MySQL setup using XAMPP
- ODBC DSN configuration required by `storage.pl`
- Database import from `opac_db.sql`
- Startup and verification steps
- Troubleshooting common errors

If you follow this in order, the project should run without setup errors.

## 1. What This Project Uses

This application is a Prolog OPAC (library) system that:
- Runs from `app.pl`
- Loads and saves data via ODBC in `storage.pl`
- Expects an ODBC Data Source Name (DSN) called `opac_db`

Main files:
- `app.pl` - entry point and menus
- `storage.pl` - SQL load/save logic via ODBC
- `opac_db.sql` - database schema + seed data
- `books.pl`, `loans.pl` - app features

## 2. Prerequisites

Install these first:

1. SWI-Prolog (64-bit recommended)
2. XAMPP (for MariaDB/MySQL)
3. ODBC driver (match SWI-Prolog architecture)
   - Recommended: MariaDB Connector/ODBC 64-bit
   - Alternative: MySQL Connector/ODBC 8.x 64-bit

Important: If SWI-Prolog is 64-bit, install a 64-bit ODBC driver and create DSN using 64-bit ODBC Administrator.

## 3. Install and Verify SWI-Prolog

1. Install SWI-Prolog from its official installer.
2. Open a new PowerShell and test:

```powershell
swipl --version
```

If `swipl` is not recognized, use full path (default install path):

```powershell
& "C:\Program Files\swipl\bin\swipl.exe" --version
```

Optional (recommended): Add `C:\Program Files\swipl\bin` to your PATH so `swipl` works globally.

## 4. Start MariaDB in XAMPP

1. Open XAMPP Control Panel.
2. Start `MySQL`.
3. Confirm it is running (green/running state).

## 5. Create Database and Import SQL

Use either phpMyAdmin or MySQL command line.

### Option A: phpMyAdmin

1. Open `http://localhost/phpmyadmin`
2. Create a database named `opac_db`.
3. Select `opac_db`.
4. Import `opac_db.sql` from this repo.

### Option B: MySQL CLI

From PowerShell:

```powershell
# Adjust path if your XAMPP is installed elsewhere
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "CREATE DATABASE IF NOT EXISTS opac_db;"
& "C:\xampp\mysql\bin\mysql.exe" -u root opac_db < opac_db.sql
```

If your MariaDB user has a password, add `-p` and enter it when prompted.

## 6. Configure ODBC DSN (Required)

The app expects a DSN named exactly: `opac_db`

1. Open 64-bit ODBC Data Source Administrator:

```text
C:\Windows\System32\odbcad32.exe
```

2. Go to `System DSN` tab.
3. Click `Add`.
4. Select your installed driver:
   - `MariaDB ODBC 3.x Driver` (recommended), or
   - `MySQL ODBC 8.0 Unicode Driver`
5. Fill connection details:
   - Data Source Name: `opac_db`
   - Server: `127.0.0.1` (or `localhost`)
   - Port: `3306`
   - User: `root` (or your MariaDB username)
   - Password: your MariaDB password (blank by default on many XAMPP setups)
   - Database: `opac_db`
6. Click `Test` and confirm success.
7. Save the DSN.

## 7. Verify ODBC Visibility from Prolog

Run:

```powershell
& "C:\Program Files\swipl\bin\swipl.exe"
```

Then in Prolog:

```prolog
?- use_module(library(odbc)).
?- odbc_data_source(opac_db, _).
```

Expected: query succeeds (returns true or a binding), no IM002/DSN error.

## 8. Run the OPAC App

From project folder:

```powershell
& "C:\Program Files\swipl\bin\swipl.exe" -q -s app.pl
```

Expected startup:
- Main menu appears
- No fatal initialization exception

## 9. Runtime Behavior Notes

- With valid ODBC DSN: app syncs data from SQL on startup and saves to SQL.
- Without valid DSN: current code falls back to in-memory mode and prints informative messages.
  - You can still use menus in-memory.
  - SQL persistence is skipped until DSN is fixed.

## 10. Common Errors and Fixes

### Error: `swipl` is not recognized

Cause:
- SWI-Prolog not installed or not in PATH

Fix:
- Install SWI-Prolog
- Use full executable path
- Optionally add SWI `bin` folder to PATH

### Error: `IM002 ... Data source name not found`

Cause:
- DSN missing, wrong DSN name, or wrong ODBC architecture

Fix:
1. Ensure DSN name is exactly `opac_db`
2. Create DSN in 64-bit ODBC admin (`System32\odbcad32.exe`)
3. Ensure 64-bit ODBC driver is installed
4. Re-test DSN connection in ODBC dialog

### Error: ODBC driver not listed in Add DSN

Cause:
- Driver not installed

Fix:
- Install MariaDB Connector/ODBC (or MySQL Connector/ODBC), matching bitness

### Error: Access denied for user/root login failed

Cause:
- Wrong DB credentials in DSN

Fix:
- Update DSN username/password to match MariaDB account

### Error: SQL tables missing

Cause:
- `opac_db.sql` not imported into `opac_db`

Fix:
- Re-import SQL file into `opac_db`

### Error: MySQL/MariaDB connection refused

Cause:
- MariaDB service not running in XAMPP or wrong host/port

Fix:
- Start MySQL in XAMPP
- Check host (`127.0.0.1`) and port (`3306`) in DSN

## 11. Fresh Setup Checklist

Use this quick checklist when setting up a new machine:

1. Install SWI-Prolog 64-bit
2. Install XAMPP and start MySQL
3. Create database `opac_db`
4. Import `opac_db.sql`
5. Install MariaDB/MySQL ODBC driver 64-bit
6. Create System DSN named `opac_db`
7. Test DSN in ODBC Admin
8. Run Prolog ODBC test (`odbc_data_source/2`)
9. Run app (`swipl -q -s app.pl`)

If all nine pass, the project is correctly configured.

## 12. Optional: Improve Command Convenience

If you want cleaner commands:

1. Add SWI-Prolog `bin` to PATH
2. Create a small `run.ps1` in project root:

```powershell
swipl -q -s app.pl
```

Then run with:

```powershell
.\run.ps1
```

---

For maintainers:
- Keep DSN name stable as `opac_db` unless you also update connection logic in `storage.pl`.
- If migrating from MariaDB to another RDBMS, update ODBC driver + DSN settings accordingly.
