SET SEARCH_PATH TO Library;

-- Import Data for Holding
\Copy Holding FROM 'data/Holding.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Contributor
\Copy Contributor FROM 'data/Contributor.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for HoldingContributor
\Copy HoldingContributor FROM 'data/HoldingContributor.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Ward
\Copy Ward FROM 'data/Ward.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryBranch
\Copy LibraryBranch FROM 'data/LibraryBranch.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryRoom
\Copy LibraryRoom FROM 'data/LibraryRoom.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryHours
\Copy LibraryHours FROM 'data/LibraryHours.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryCatalogue
\Copy LibraryCatalogue FROM 'data/LibraryCatalogue.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryHolding
\Copy LibraryHolding FROM 'data/LibraryHolding.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for LibraryEvent
\Copy LibraryEvent FROM 'data/LibraryEvent.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventAgeGroup
\Copy EventAgeGroup FROM 'data/EventAgeGroup.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSubject
\Copy EventSubject FROM 'data/EventSubject.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSchedule
\Copy EventSchedule FROM 'data/EventSchedule.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Patron
\Copy Patron FROM 'data/Patron.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Checkout
\Copy Checkout FROM 'data/Checkout.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Return
\Copy Return FROM 'data/Return.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Review
\Copy Review FROM 'data/Review.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for RoomBooking
\Copy RoomBooking FROM 'data/RoomBooking.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for EventSignUp
\Copy EventSignUp FROM 'data/EventSignUp.csv' With CSV DELIMITER ',' HEADER;
