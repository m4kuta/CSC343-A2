/* 
 * This code is provided solely for the personal and private use of students 
 * taking the CSC343H course at the University of Toronto. Copying for purposes 
 * other than this use is expressly prohibited. All forms of distribution of 
 * this code, including but not limited to public repositories on GitHub, 
 * GitLab, Bitbucket, or any other online platform, whether as given or with 
 * any changes, are expressly prohibited. 
*/ 

import java.sql.*;
import java.util.Date;
import java.util.Arrays;
import java.util.List;

// TODO Is this allowed?
import java.util.Scanner;

public class Assignment2 {
	/////////
	// DO NOT MODIFY THE VARIABLE NAMES BELOW.
	
	// A connection to the database
	Connection connection;

	// Can use if you wish: seat letters
	List<String> seatLetters = Arrays.asList("A", "B", "C", "D", "E", "F");

	Assignment2() throws SQLException {
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Connects and sets the search path.
	 *
	 * Establishes a connection to be used for this session, assigning it to
	 * the instance variable 'connection'.  In addition, sets the search
	 * path to 'air_travel, public'.
	 *
	 * @param  url       the url for the database
	 * @param  username  the username to connect to the database
	 * @param  password  the password to connect to the database
	 * @return           true if connecting is successful, false otherwise
	 */
	public boolean connectDB(String URL, String username, String password) {
		// Implement this method!
		try {
			connection = DriverManager.getConnection(URL, username, password);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return false;
	}

	/**
	 * Closes the database connection.
	 *
	 * @return true if the closing was successful, false otherwise
	 */
	public boolean disconnectDB() {
		// Implement this method!
		return false;
	}
   
   /* ======================= Airline-related methods ======================= */

   /**
    * Attempts to book a flight for a passenger in a particular seat class. 
    * Does so by inserting a row into the Booking table.
    *
    * Read handout for information on how seats are booked.
    * Returns false if seat can't be booked, or if passenger or flight cannot be found.
    *
    * 
    * @param  passID     id of the passenger
    * @param  flightID   id of the flight
    * @param  seatClass  the class of the seat (economy, business, or first) 
    * @return            true if the booking was successful, false otherwise. 
    */
   	public boolean bookSeat(int passID, int flightID, String seatClass) {
    	// Implement this method!
		
		
		// Find total capacity for seatClass on flightID
		String q1 = "select capacity_? from flight join plane on plane = tail_number where id = ?";
		PreparedStatement ps1 = connection.prepareStatement(q1);
		ResultSet capacity = ps1.executeQuery();
		
		// Find how many seats are already occupied for seatClass on flightID
		String q2 = "select count(*) as booked from booking where flight_id = 5 and seat_class = 'economy' group by flight_id, seat_class order by flight_id, seat_class";
		PreparedStatement ps2 = connection.prepareStatement(q2);
		ResultSet booked = ps2.executeQuery();

		// Determine appropriate seat
		String q3;
		PreparedStatement ps3;
		ResultSet resultSet3;

		
		// Insert booking
		String q4;
		PreparedStatement ps4;
		ResultSet resultSet4;

		if () {
			return true;
		}

		return false;
   	}

	/**
	* Attempts to upgrade overbooked economy passengers to business class
	* or first class (in that order until each seat class is filled).
	* Does so by altering the database records for the bookings such that the
	* seat and seat_class are updated if an upgrade can be processed.
	*
	* Upgrades should happen in order of earliest booking timestamp first.
	*
	* If economy passengers are left over without a seat (i.e. more than 10 overbooked passengers or not enough higher class seats), 
	* remove their bookings from the database.
	* 
	* @param  flightID  The flight to upgrade passengers in.
	* @return           the number of passengers upgraded, or -1 if an error occured.
    */
	public int upgrade(int flightID) {
		// Implement this method!

		return -1;
	}


	/* ----------------------- Helper functions below  ------------------------- */

		// A helpful function for adding a timestamp to new bookings.
		// Example of setting a timestamp in a PreparedStatement:
		// ps.setTimestamp(1, getCurrentTimeStamp());

		/**
		* Returns a SQL Timestamp object of the current time.
		* 
		* @return           Timestamp of current time.
		*/
	private java.sql.Timestamp getCurrentTimeStamp() {
		java.util.Date now = new java.util.Date();
		return new java.sql.Timestamp(now.getTime());
	}

	// Add more helper functions below if desired.


  
  /* ----------------------- Main method below  ------------------------- */

	public static void main(String[] args) {
		// You can put testing code in here. It will not affect our autotester.
		System.out.println("Running the code!");

		System.out.println("What do you want to do:");
		Scanner userInput = new Scanner(System.in);
		String command = userInput.nextLine();
	}

}
