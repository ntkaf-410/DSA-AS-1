import ballerina/io;

// A command-line client for the Library & Resource Management API that
// demonstrates loaning/booking, a global asset view, campus filtering,
// an overdue dashboard, and schedule management.
public function main() {
    io:println("==================================================");
    io:println(" Library & Resource Management System - CLI Client");
    io:println(" Connected to: " + apiBaseUrl);
    io:println("==================================================");

    boolean running = true;
    while running {
        printMainMenu();
        string choice = io:readln("Select an option: ").trim();
        error? outcome = ();

        if choice == "1" {
            outcome = runLoanBookingMenu();
        } else if choice == "2" {
            outcome = runGlobalView();
        } else if choice == "3" {
            outcome = runCampusView();
        } else if choice == "4" {
            outcome = runOverdueDashboard();
        } else if choice == "5" {
            outcome = runScheduleManager();
        } else if choice == "0" {
            running = false;
            io:println("Goodbye.");
        } else {
            io:println("Invalid option. Please choose a number from the menu.");
        }

        if outcome is error {
            io_error("Unexpected error: " + outcome.message());
        }
    }
}

function printMainMenu() {
    io:println("\n--------------------------------------------------");
    io:println("1. Loan / Book a Resource");
    io:println("2. Global Asset View (all campuses)");
    io:println("3. Campus / Institution View");
    io:println("4. Overdue Dashboard");
    io:println("5. Schedule Manager");
    io:println("0. Exit");
    io:println("--------------------------------------------------");
}
