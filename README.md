# sql_election_race




This project showcases a relational database designed for managing a secure and auditable voting system using SQL. It includes key features such as voter registration, ballot tracking, race and candidate management, and robust auditing mechanisms to log all changes. Business rules are enforced through triggers, such as restricting modifications to voter records to authorized users (e.g., the Secretary of State) and preventing overvotes by ensuring ballots comply with race-specific voting limits. The schema is normalized with primary and foreign keys to maintain data integrity, while CHECK constraints and dynamic validation add further security. Audit tables and triggers capture every insert, update, and delete operation, providing a transparent record of all activity. This project demonstrates role-based access control, data validation, and automation through triggers, making it a practical solution for managing election data.
