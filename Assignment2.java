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
import java.util.Scanner;
import java.lang.Math;

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
		try {
			// Connect
			connection = DriverManager.getConnection(URL, username, password);
			
			// Set search path
			String q = "set search_path to air_travel, public";
			PreparedStatement ps = connection.prepareStatement(q);
			ps.executeUpdate();

			return true;
		} 
		catch (SQLException e) {
			e.printStackTrace();
			return false;
		}
	}

	/**
	* Closes the database connection.
	*
	* @return true if the closing was successful, false otherwise
	*/
	public boolean disconnectDB() {
		try {
			connection.close();
		} catch (SQLException e) {
			return false;
		}
		return true;
	}
   
  /* ======================= Airline-related methods ======================= */

	/**
	* Attempts to book a flight for a passenger in a particular seat class. 
	* Does so by inserting a row into the Booking table.
	*
	* Read handout for information on how seats are booked.
	* Returns false if seat can't be booked, or if passenger or flight cannot be 
	* found.
	*
	* 
	* @param  passID     id of the passenger
	* @param  flightID   id of the flight
	* @param  seatClass  the class of the seat (economy, business, or first) 
	* @return            true if the booking was successful, false otherwise. 
	*/
	public boolean bookSeat(int passID, int flightID, String seatClass) {
		// Implement this method!
		double capacityFirst;
		double capacityBusiness;
		double capacityEconomy;
		int booked;

		try { 
			// Find total capacity of each seat class on flightID
			String q1 = 
			"select * from flight join plane on plane = tail_number where id = ?";
			PreparedStatement ps1 = connection.prepareStatement(q1);
			ps1.setInt(1, flightID);
			ResultSet rs1 = ps1.executeQuery();
			if (!rs1.next()) {
				return false;
			}
			capacityFirst = rs1.getInt("capacity_first");
			capacityBusiness = rs1.getInt("capacity_business");
			capacityEconomy = rs1.getInt("capacity_economy");
			
			
			// Find how many seats are already occupied for seatClass on flightID
			String q2 = 
			"select COALESCE((select count(*) from booking where flight_id = ? " 
			+ "and seat_class = (?::seat_class) group by flight_id, seat_class), 0)";
			PreparedStatement ps2 = connection.prepareStatement(q2);
			ps2.setInt(1, flightID);
			ps2.setString(2, seatClass);
			ResultSet rs2 = ps2.executeQuery();
			if (!rs2.next()) {
				return false;
			}
			booked = rs2.getInt("coalesce");
		} 
		catch (SQLException e) {
			e.printStackTrace();
			return false;
		}

		// Determine appropriate row and letter
		double startRow;
		Integer row;
		String letter;

		if (seatClass.equalsIgnoreCase("first")) {
			if (capacityFirst - booked > 0) {
				row = booked / 6 + 1;
				letter = seatLetters.get(booked % 6);
			} else {return false;}
		}
		else if (seatClass.equalsIgnoreCase("business")) {
			if (capacityBusiness - booked > 0) {
				startRow = Math.ceil(capacityFirst / 6) + 1;
				row = (int) startRow + booked / 6;
				letter = seatLetters.get(booked % 6);
			} else {return false;}
		}
		else {
			if (capacityEconomy - booked > 0) {
				startRow = Math.ceil((capacityFirst + capacityBusiness) / 6) + 1;
				row = (int) startRow + booked / 6;
				letter = seatLetters.get(booked % 6);
			} else if (capacityEconomy - booked > -10) {
				row = null;
				letter = null;
			} else {return false;}
		}
		
		try {
			// Get latest booking.id
			String q3 = "select COALESCE((select max(id) from booking), 0)";
			PreparedStatement ps3 = connection.prepareStatement(q3);
			ResultSet rs3 = ps3.executeQuery();
			if (!rs3.next()) {
				return false;
			}
			int id = rs3.getInt("coalesce") + 1;

			// Get seat price
			String q4 = "select " + seatClass + " from price where flight_id = ?";
			PreparedStatement ps4 = connection.prepareStatement(q4);
			ps4.setInt(1, flightID);
			ResultSet rs4 = ps4.executeQuery();
			if (!rs4.next()) {
				return false;
			}
			int price = rs4.getInt(seatClass);

			// Insert booking
			String q5 = 
			"insert into booking values (?, ?, ?, ?, ?, (?::seat_class), ?, ?)";
			PreparedStatement ps5 = connection.prepareStatement(q5);
			ps5.setInt(1, id);
			ps5.setInt(2, passID);
			ps5.setInt(3, flightID);
			ps5.setTimestamp(4, getCurrentTimeStamp());
			ps5.setInt(5, price); 
			ps5.setString(6, seatClass);
			if (row == null) { // Use SQL's NULL in place
				ps5.setNull(7, Types.INTEGER);
				ps5.setNull(8, Types.CHAR);
			} else {
				ps5.setInt(7, row);
				ps5.setString(8, letter);
			}
			ps5.executeUpdate();
			return true;
		} 
		catch (SQLException e) {
			e.printStackTrace();
			return false;
		}		
	}

	/**
	* Attempts to upgrade overbooked economy passengers to business class
	* or first class (in that order until each seat class is filled).
	* Does so by altering the database records for the bookings such that the
	* seat and seat_class are updated if an upgrade can be processed.
	*
	* Upgrades should happen in order of earliest booking timestamp first.
	*
	* If economy passengers are left over without a seat (i.e. more than 10 
  * overbooked passengers or not enough higher class seats), 
	* remove their bookings from the database.
	* 
	* @param  flightID  The flight to upgrade passengers in.
	* @return the number of passengers upgraded, or -1 if an error occured.
    */
	public int upgrade(int flightID) {
		int startBRow, startBSeatIndex, startFRow, startFSeatIndex;
		int upgraded = 0;
		try {
			// Part 1: Retrieve the plane's business and first class capacity
			String SeatsQuery =
				"select capacity_business, capacity_first " +
				"from flight join plane on flight.plane = plane.tail_number " +
				"where id = ?";
			PreparedStatement psSeats = connection.prepareStatement(SeatsQuery);
			psSeats.setInt(1, flightID);
			ResultSet rsSeats = psSeats.executeQuery();

			if (!rsSeats.next()) return -1; // Non-existent flight, error.
			int fSeats = rsSeats.getInt("capacity_first");
			int lastFRow = fSeats == 0 ? 0 : fSeats / 6 + 1;
			int lastFSeatIndex = fSeats % 6 + 1;
			int bSeats = rsSeats.getInt("capacity_business");
			int lastBRow = bSeats == 0 ? 0 : lastFRow + bSeats / 6 + 1;
			int lastBSeatIndex = bSeats % 6 + 1;

			// Part 2: Retrieve starting positions for business and first class
			String vacantBQuery =
				"select row, letter " +
				"from booking " +
				"where flight_id = ? and seat_class = 'business' " +
				"order by row desc, letter desc";
			PreparedStatement psVacantB =
					connection.prepareStatement(vacantBQuery);
			psVacantB.setInt(1, flightID);
			ResultSet rsVacantB = psVacantB.executeQuery();

			if (!rsVacantB.next()) { // No Business class passengers
				startBRow = lastFRow + 1;
				startBSeatIndex = 1;
			} else {
				startBRow = rsVacantB.getInt("row");
				startBSeatIndex =
						rsVacantB.getString("letter").charAt(0) - 'A' + 1;
				if (startBSeatIndex == 6) startBRow++;
				startBSeatIndex = startBSeatIndex % 6 + 1;
			}

			String vacantFQuery =
				"select row, letter " +
				"from booking " +
				"where flight_id = ? and seat_class = 'first' " +
				"order by row desc, letter desc";
			PreparedStatement psVacantF =
					connection.prepareStatement(vacantFQuery);
			psVacantF.setInt(1, flightID);
			ResultSet rsVacantF = psVacantF.executeQuery();

			if (!rsVacantF.next()) { // No First class passengers
				startFRow = 1;
				startFSeatIndex = 1;
			} else {
				startFRow = rsVacantF.getInt("row");
				startFSeatIndex =
						rsVacantF.getString("letter").charAt(0) - 'A' + 1;
				if (startFSeatIndex == 6) startFRow++;
				startFSeatIndex = startFSeatIndex % 6 + 1;
			}

			// Part 3: Retrieve all passengers booked by flight ID with null
			// values, sort by earliest booking
			String overbookedQuery =
				"select * " +
				"from booking " +
				"where flight_id = ? " +
						"and seat_class = 'economy' " +
						"and row is null " +
						"and letter is null " +
				"order by datetime";
			PreparedStatement psOverbooked =
					connection.prepareStatement(overbookedQuery);
			psOverbooked.setInt(1, flightID);
			ResultSet rsOverbooked = psOverbooked.executeQuery();

			boolean remaining = rsOverbooked.next();
			if (!remaining) return upgraded; // No overbooked passengers.
			String currentClass = "business";
			int currRow = startBRow;
			int currSeatIndex = startBSeatIndex;
			int lastRow = lastBRow;
			int lastSeatIndex = lastBSeatIndex;

			// Part 4: Upgrade until no remaining overbooked or seats are full
			while (remaining
					&& ((currentClass.equals("business")
						|| currRow < lastRow
						|| (currRow == lastRow
							&& currSeatIndex < lastSeatIndex)))) {
				if (currentClass.equals("business")
					&& (currRow > lastRow
						|| (currRow == lastRow
							&& currSeatIndex >= lastSeatIndex))) {
					currentClass = "first";
					currRow = startFRow;
					currSeatIndex = startFSeatIndex;
					lastRow = lastFRow;
					lastSeatIndex = lastFSeatIndex;
					continue;
				}
				String updateSeating =
						"update booking " +
						"set seat_class = ?::seat_class, row = ?, letter = ? " +
						"where id = ? ";
				PreparedStatement psUpdateSeating =
						connection.prepareStatement(updateSeating);
				psUpdateSeating.setObject(
						1,
						currentClass,
						Types.OTHER
				);
				psUpdateSeating.setInt(
						2,
						currRow
				);
				psUpdateSeating.setString(
						3,
						String.valueOf((char)(currSeatIndex + 'A' - 1))
				);
				psUpdateSeating.setInt(
						4,
						rsOverbooked.getInt("id")
				);
				psUpdateSeating.executeUpdate();
				upgraded++;

				if (currSeatIndex == 6) currRow++;
				currSeatIndex = currSeatIndex % 6 + 1;

				remaining = rsOverbooked.next();
			}

			// Part 5: If Business and First class is full,
			// delete remaining overbooked passengers
			if (remaining) {
				do {
					String deleteBooking =
						"delete from booking " +
						"where id = ?";
					PreparedStatement psDeleteBooking =
							connection.prepareStatement(deleteBooking);
					psDeleteBooking.setInt(
							1,
							rsOverbooked.getInt("id")
					);
					psDeleteBooking.executeUpdate();

					remaining = rsOverbooked.next();
				} while (remaining);
			}

			return upgraded;
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return -1;
	}


	/* ---------------------- Helper functions below  ---------------------- */

	// A helpful function for adding a timestamp to new bookings.
	// Example of setting a timestamp in a PreparedStatement:
	// ps.setTimestamp(1, getCurrentTimeStamp());

	/**
	* Returns a SQL Timestamp object of the current time.
	* 
	* @return           Timestamp of current time.
	*/
	private java.sql.Timestamp getCurrentTimeStamp() {
		Date now = new Date();
		return new java.sql.Timestamp(now.getTime());
	}

	// Add more helper functions below if desired.
	

  /* ------------------------- Main method below  ------------------------- */

	public static void main(String[] args) {
		// You can put testing code in here. It will not affect our autotester.
		try {
			Assignment2 instance = new Assignment2();
			System.out.println("===Connecting===");				
			Scanner userInput = new Scanner(System.in);

			String url = "jdbc:postgresql://localhost:5432/csc343h-";
			String pass = "";
			System.out.println("Enter username:");
			String user = userInput.nextLine();
			if (instance.connectDB(url + user, user, pass)) {
				System.out.println("[Connected]");
			}
	
			boolean running = true;
			while (running) {
				System.out.println("Enter a command:");
				System.out.println("[0] Disconnect");
				System.out.println("[1] Book");
				System.out.println("[2] Upgrade");
				String function = userInput.nextLine();
				switch (function) {
					case "0":
						System.out.println("===Disconnecting===");
						if (instance.disconnectDB()) {
							System.out.println("[Disconnected]");
							running = false;
						}
						break;
					case "1":
						System.out.println("===Booking===");
						System.out.println("Enter passport id:");
						int passID = Integer.parseInt(userInput.nextLine());
						System.out.println("Enter flight id:");
						int flightID = Integer.parseInt(userInput.nextLine());
						System.out.println("Enter seat class:");
						String seatClass = userInput.nextLine();

						if (instance.bookSeat(passID, flightID, seatClass)) {
							System.out.println("[Booked]");
							String bookingInfo = String.format("passID: %d, flightID: %d," 
							+ " seatClass: %s", passID, flightID, seatClass);
							System.out.println(bookingInfo);
						}
						break;
					case "2":
						System.out.println("===Upgrading===");
						System.out.println("Enter flight id:");
						flightID = userInput.nextInt();
						int result = instance.upgrade(flightID);
						if (result != -1) {
							System.out.println("[Upgraded]");
							System.out.println(result + " passengers upgraded.");
						}
						break;
				}
			}
			userInput.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
}	
