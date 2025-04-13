CREATE DATABASE political_campaign_db;
CREATE SCHEMA IF NOT EXISTS campaign;

----------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS campaign.campaign_donor (
    donor_id SERIAL PRIMARY KEY,  -- Auto-incrementing ID, PK
    name VARCHAR(100) NOT NULL,   -- Full name or organization
    email VARCHAR(255) NOT NULL UNIQUE,  -- Contact email
    phone_number VARCHAR(100) NOT NULL UNIQUE,  -- Contact phone
    donor_type VARCHAR(30) CHECK (donor_type IN ('Private', 'Organisation'))  -- Donor type constraint
);
COMMENT ON TABLE campaign.campaign_donor IS 'Table for storing donor information for a campaign.';
COMMENT ON COLUMN campaign.campaign_donor.donor_id IS 'Unique identifier for a donor (auto-incremented).';
COMMENT ON COLUMN campaign.campaign_donor.name IS 'Full name or organization name of the donor.';
COMMENT ON COLUMN campaign.campaign_donor.email IS 'Contact email address of the donor.';
COMMENT ON COLUMN campaign.campaign_donor.phone_number IS 'Contact phone number of the donor.';
COMMENT ON COLUMN campaign.campaign_donor.donor_type IS 'Type of donor: either Private or Organisation.';

INSERT INTO campaign.campaign_donor (name, email, phone_number, donor_type)
VALUES 
    ('Jane Doe', 'jane@example.com', '555-1234', 'Private'),
    ('Green Future Org', 'contact@greenfuture.org', '555-5678', 'Organisation');

ALTER TABLE campaign.campaign_donor 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.election (
    election_id SERIAL PRIMARY KEY,  -- Unique identifier for the election
    election_date DATE CHECK (election_date >= '2000-01-01'),  -- Date of election, must be after January 1, 2000
    type VARCHAR(50) CHECK (type IN ('Presidential', 'Congressional', 'Local'))  -- Type of election
);
-- Add comments to each column
COMMENT ON TABLE campaign.election IS 'Table for storing election details.';
COMMENT ON COLUMN campaign.election.election_id IS 'Unique identifier for the election (auto-incremented).';
COMMENT ON COLUMN campaign.election.election_date IS 'Date when the election takes place . CHECK constraint ensures the year is >= 2000.';
COMMENT ON COLUMN campaign.election.type IS 'Type of election: either Presidential, Congressional, or Local.';

INSERT INTO campaign.election (election_date, type)
VALUES 
    ('2024-11-05', 'Presidential'),
    ('2025-06-15', 'Local');

ALTER TABLE campaign.election 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.issue_report (
    issue_id SERIAL PRIMARY KEY,  -- Unique issue identifier (auto-incremented)
    election_id INT NOT NULL REFERENCES campaign.election(election_id),  -- Links issue to a specific election (Foreign Key)
    description TEXT NOT NULL,  -- Detailed description of the issue
    reported_by VARCHAR(255) NOT NULL,  -- Name of the person reporting the issue
    status VARCHAR(50) CHECK (status IN ('Open', 'Resolved'))  -- Status of the report
);
-- Add comments to each column
COMMENT ON TABLE campaign.issue_report IS 'Table for storing issue reports related to elections.';
COMMENT ON COLUMN campaign.issue_report.issue_id IS 'Unique issue identifier (auto-incremented).';
COMMENT ON COLUMN campaign.issue_report.election_id IS 'Links issue to a specific election by its Election_ID. Foreign Key reference to election.election_id.';
COMMENT ON COLUMN campaign.issue_report.description IS 'Detailed description of the issue being reported.';
COMMENT ON COLUMN campaign.issue_report.reported_by IS 'Name of the person reporting the issue.';
COMMENT ON COLUMN campaign.issue_report.status IS 'Status of the issue report: either Open or Resolved.';

INSERT INTO campaign.issue_report (election_id, description, reported_by, status)
VALUES 
    (1, 'Polling station opened late', 'Alice Johnson', 'Open'),
    (2, 'Missing ballots reported', 'Bob Smith', 'Resolved');

ALTER TABLE campaign.issue_report 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.campaign (
    campaign_id SERIAL PRIMARY KEY,  -- Unique identifier for the campaign (auto-incremented)
    candidate_first_name VARCHAR(100) NOT NULL,  -- First name of the candidate
    candidate_last_name VARCHAR(100) NOT NULL,   -- Last name of the candidate
    party_affiliation VARCHAR(100) NOT NULL,     -- Political party associated with the campaign
    election_id INT NOT NULL REFERENCES campaign.election(election_id) -- Links campaign to an election (Foreign Key)
);
-- Add comments to each column
COMMENT ON TABLE campaign.campaign IS 'Table for storing campaign details for each candidate.';
COMMENT ON COLUMN campaign.campaign.campaign_id IS 'Unique identifier for the campaign (auto-incremented).';
COMMENT ON COLUMN campaign.campaign.candidate_first_name IS 'First name of the candidate running in the campaign.';
COMMENT ON COLUMN campaign.campaign.candidate_last_name IS 'Last name of the candidate running in the campaign.';
COMMENT ON COLUMN campaign.campaign.party_affiliation IS 'Political party associated with the campaign.';
COMMENT ON COLUMN campaign.campaign.election_id IS 'Links the campaign to a specific election (Foreign Key reference to election.election_id).';

INSERT INTO campaign.campaign (candidate_first_name, candidate_last_name, party_affiliation, election_id)
VALUES 
    ('Laura', 'White', 'Progressive Party', 1),
    ('Mike', 'Taylor', 'Unity Party', 2);

ALTER TABLE campaign.campaign 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.voter (
    voter_id SERIAL PRIMARY KEY,  -- Unique identifier for the voter (auto-incremented)
    first_name VARCHAR(100) NOT NULL,  -- First name of the voter
    last_name VARCHAR(100) NOT NULL,   -- Last name of the voter
    date_of_birth DATE CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),  -- Legal voting age check
    address TEXT,  -- Voter’s registration street name, building number, apartment building
    city TEXT,     -- City where voter is registered
    state TEXT,    -- State where voter is registered
    zip_code TEXT, -- Zip code of voter’s registration place
    election_id INT NOT NULL REFERENCES campaign.election(election_id)  -- Foreign Key reference to election.election_id
);

-- Add comments to each column
COMMENT ON TABLE campaign.voter IS 'Table for storing voter registration details, linked to a specific election.';
COMMENT ON COLUMN campaign.voter.voter_id IS 'Unique identifier for the voter (auto-incremented).';
COMMENT ON COLUMN campaign.voter.first_name IS 'First name of the voter.';
COMMENT ON COLUMN campaign.voter.last_name IS 'Last name of the voter.';
COMMENT ON COLUMN campaign.voter.date_of_birth IS 'Voter’s date of birth. CHECK constraint ensures the voter is at least 18 years old.';
COMMENT ON COLUMN campaign.voter.address IS 'Voter’s registration street name, building number, apartment building.';
COMMENT ON COLUMN campaign.voter.city IS 'City where the voter is registered.';
COMMENT ON COLUMN campaign.voter.state IS 'State where the voter is registered.';
COMMENT ON COLUMN campaign.voter.zip_code IS 'Zip code of the voter’s registration place.';
COMMENT ON COLUMN campaign.voter.election_id IS 'Links the voter to a specific election by its Election_ID. Foreign Key reference to election.election_id.';

INSERT INTO campaign.voter (first_name, last_name, date_of_birth, address, city, state, zip_code, election_id)
VALUES 
    ('Alice', 'Johnson', '1990-03-15', '123 Main St', 'Springfield', 'IL', '62704', 1),
    ('Bob', 'Smith', '1985-07-20', '456 Elm St', 'Dayton', 'OH', '45402', 2);

ALTER TABLE campaign.voter 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.survey_response (
    survey_id SERIAL PRIMARY KEY,  -- Unique identifier for the survey response
    voter_id INT NOT NULL REFERENCES campaign.voter(voter_id),  -- Links response to a voter
    election_id INT NOT NULL REFERENCES campaign.election(election_id),  -- Links response to an election
    key_issue TEXT  -- Main issue with candidate
);
-- Add comments to each column
COMMENT ON TABLE campaign.survey_response IS 'Stores responses to surveys from voters';
COMMENT ON COLUMN campaign.survey_response.survey_id IS 'Unique identifier for the survey response';
COMMENT ON COLUMN campaign.survey_response.voter_id IS 'Links response to a voter (FK to voter.voter_id)';
COMMENT ON COLUMN campaign.survey_response.election_id IS 'Links response to an election (FK to election.election_id)';
COMMENT ON COLUMN campaign.survey_response.key_issue IS 'Main issue with candidate';

INSERT INTO campaign.survey_response (voter_id, election_id, key_issue)
VALUES 
    (1, 1, 'Healthcare'),
    (2, 2, 'Education');

ALTER TABLE campaign.survey_response 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.campaign_donation (
    donation_id SERIAL PRIMARY KEY,  -- Unique donation record identifier
    donor_id INT NOT NULL REFERENCES campaign.campaign_donor(donor_id),  -- Links to the donor who made the contribution
    campaign_id INT NOT NULL REFERENCES campaign.campaign(campaign_id),  -- Links the donation to a specific campaign
    contribution DECIMAL(10,2) CHECK (contribution > 0),  -- Amount donated, must be greater than 0
    date_received DATE NOT NULL  -- Date the donation was received
);
-- Add comments to each column
COMMENT ON TABLE campaign.campaign_donation IS 'Tracks donations made by donors';
COMMENT ON COLUMN campaign.campaign_donation.donation_id IS 'Unique donation record identifier';
COMMENT ON COLUMN campaign.campaign_donation.donor_id IS 'Links to the donor who made the contribution (FK to campaign_donor.donor_id)';
COMMENT ON COLUMN campaign.campaign_donation.campaign_id IS 'Links the donation to a specific campaign (FK to campaign.campaign_id)';
COMMENT ON COLUMN campaign.campaign_donation.contribution IS 'Amount donated (must be greater than 0)';
COMMENT ON COLUMN campaign.campaign_donation.date_received IS 'Date the donation was received';

INSERT INTO campaign.campaign_donation (donor_id, campaign_id, contribution, date_received)
VALUES 
    (1, 1, 500.00, '2024-05-01'),
    (2, 2, 1500.00, '2024-05-03');

ALTER TABLE campaign.campaign_donation
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.event (
    event_id SERIAL PRIMARY KEY,  -- Unique identifier for an event
    campaign_id INT NOT NULL REFERENCES campaign.campaign(campaign_id) ON DELETE CASCADE,  -- Links to the campaign that organized the event
    name VARCHAR(255) NOT NULL,  -- Name of the event (e.g., "Rally in NYC")
    date DATE NOT NULL,  -- Event date
    location VARCHAR(255) NOT NULL,  -- Venue of the event
    type VARCHAR(50) CHECK (type IN ('Rally', 'Town Hall', 'Debate'))  -- Type of event
);

-- Add comments to each column
COMMENT ON TABLE campaign.event IS 'Tracks campaign events like rallies, town halls';
COMMENT ON COLUMN campaign.event.event_id IS 'Unique identifier for an event';
COMMENT ON COLUMN campaign.event.campaign_id IS 'Links to the campaign that organized the event (FK to campaign.campaign_id)';
COMMENT ON COLUMN campaign.event.name IS 'Name of the event (e.g., "Rally in NYC")';
COMMENT ON COLUMN campaign.event.date IS 'Event date';
COMMENT ON COLUMN campaign.event.location IS 'Venue of the event';
COMMENT ON COLUMN campaign.event.type IS 'Type of event (e.g., Rally, Town Hall, Debate)';

INSERT INTO campaign.event (campaign_id, name, date, location, type)
VALUES 
    (1, 'Rally in Central Park', '2024-09-01', 'Central Park, NY', 'Rally'),
    (2, 'Town Hall Meeting', '2024-10-10', 'Civic Center, LA', 'Town Hall');

ALTER TABLE campaign.event 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.campaign_volunteer (
    volunteer_id SERIAL PRIMARY KEY,  -- Unique identifier for a volunteer
    campaign_id INT NOT NULL REFERENCES campaign.campaign(campaign_id),  -- Links to the campaign that person is volunteering for
    first_name VARCHAR(100) NOT NULL,  -- First name of volunteer
    last_name VARCHAR(100) NOT NULL,   -- Last name of volunteer
    availability VARCHAR(50) NOT NULL,  -- Days/times the volunteer is available (e.g., "Weekends", "Full-time")
    role VARCHAR(100) NOT NULL  -- Assigned role (e.g., "Event Coordinator")
);

-- Add comments to each column
COMMENT ON TABLE campaign.campaign_volunteer IS 'Tracks campaign volunteers';
COMMENT ON COLUMN campaign.campaign_volunteer.volunteer_id IS 'Unique identifier for a volunteer';
COMMENT ON COLUMN campaign.campaign_volunteer.campaign_id IS 'Links to the campaign that the person is volunteering for (FK to campaign.campaign_id)';
COMMENT ON COLUMN campaign.campaign_volunteer.first_name IS 'First name of volunteer';
COMMENT ON COLUMN campaign.campaign_volunteer.last_name IS 'Last name of volunteer';
COMMENT ON COLUMN campaign.campaign_volunteer.availability IS 'Days/times the volunteer is available (e.g., "Weekends", "Full-time")';
COMMENT ON COLUMN campaign.campaign_volunteer.role IS 'Assigned role (e.g., "Event Coordinator")';

INSERT INTO campaign.campaign_volunteer (campaign_id, first_name, last_name, availability, role)
VALUES 
    (1, 'Emily', 'Clark', 'Weekends', 'Event Coordinator'),
    (2, 'James', 'Lee', 'Full-time', 'Field Organizer');

ALTER TABLE campaign.campaign_volunteer 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS campaign.event_attendance (
    event_id INT NOT NULL REFERENCES campaign.event(event_id),  -- Links to the attended event
    volunteer_id INT REFERENCES campaign.campaign_volunteer(volunteer_id),  -- Links to the volunteer who attended (nullable)
    task_assigned VARCHAR(50),  -- Task assigned to volunteer (e.g., "Speaker", "Attendee", "Organizer")
    PRIMARY KEY (event_id, volunteer_id)  -- Composite PK ensures uniqueness of attendance per event per volunteer
);

-- Add comments to each column
COMMENT ON TABLE campaign.event_attendance IS 'The Attendance table tracks participation in events';
COMMENT ON COLUMN campaign.event_attendance.event_id IS 'Links to the attended event (FK to event.event_id)';
COMMENT ON COLUMN campaign.event_attendance.volunteer_id IS 'Links to the volunteer who attended (nullable FK to campaign_volunteer.volunteer_id)';
COMMENT ON COLUMN campaign.event_attendance.task_assigned IS 'Task assigned to volunteer (e.g., "Speaker", "Attendee", "Organizer")';

INSERT INTO campaign.event_attendance (event_id, volunteer_id, task_assigned)
VALUES 
    (1, 1, 'Organizer'),
    (2, 2, 'Attendee');

ALTER TABLE campaign.event_attendance 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
