create database voting; 

use voting;

ALTER TABLE voter CHANGE COLUMN voting_locartion voting_location varchar(100); -- Correct spelling mistake

create table voter
(
Voter_id int primary key auto_increment,
voter_name varchar(100) not null,
voter_address varchar(100) not null,
voter_county varchar(100) not null,
voter_district varchar(10) not null,
voter_precinct varchar(10) not null,
voter_party varchar(20),
voting_location varchar(100) not null,
voter_registration_num int not null unique
)
;

create table ballot
(
ballot_id int primary key auto_increment,
voter_id int not null unique,
ballot_type varchar(10) not null,
ballot_cast_datetime datetime not null default now(),
constraint foreign key (voter_id) references voter(voter_id),
constraint check (ballot_type in ('in person', 'absentee'))
);


create table race
(
race_id int primary key auto_increment,
race_name varchar(100) not null unique,
votes_allowed int not null
);

create table candidate
(
candidate_id int primary key auto_increment,
race_id int not null,
candidate_name varchar(100) not null unique,
candidate_address varchar(100) not null,
candidate_party varchar(20),
incumbent_flag bool,
constraint foreign key (race_id) references race (race_id)
);

create table ballot_candidate
(
ballot_id int,
candidate_id int,
primary key (ballot_id, candidate_id),
constraint foreign key (ballot_id) references ballot(ballot_id),
constraint foreign key (candidate_id) references candidate(candidate_id)
);

drop trigger if exists tr_voter_bi;

delimiter //
create trigger tr_voter_bi
	before insert on voter
	for each row
begin 
	if user() not like 'secretary_of_state' then
		signal sqlstate '45000'
		set message_text = 'Voters can be added only by the Secretary of State';
    end if;
end//

delimiter ;

drop trigger if exists tr_ballot_candidate_bi;

delimiter //

create trigger tr_ballot_candidate_bi
	before insert on ballot_candidate
    for each row
begin
	declare v_race_id int;
    declare v_votes_allowed int;
    declare v_existing_votes int;
    declare v_error_msg varchar(100);
    declare v_race_name varchar(100);
    
    select  r.race_id,
			r.race_name,
			r.votes_allowed
	into	v_race_id,
			v_race_name,
            v_votes_allowed
	from	race r
    join	candidate c 
    on	    r.race_id = c.race_id
    where   c.candidate_id = new.candidate_id;
    
    select  count(*)
    into 	v_existing_votes
    from 	ballot_candidate bc
    join 	candidate c 
    on 		bc.candidate_id = c.candidate_id
    and 	c.race_id = v_race_id
    where 	bc.ballot_id = new.ballot_id;
    
    if v_existing_votes >= v_votes_allowed then
		select concat('Overvoting error: The',
					v_race_name,
                    'race allows selecting a maximum of',
                    v_votes_allowed,
                    'candidate(s) per ballot.'
                    )
		into v_error_msg;
       
       signal sqlstate '45000' set message_text = v_error_msg;
     end if;
end//

delimiter ;

drop trigger if exists tr_voter_bu;

delimiter //

create trigger tr_voter_bu
	before update on voter
    for each row
begin
	if user() not like 'secretary_of_state%' then
		signal sqlstate '45000'
        set message_text = 'Voters can be updated only by the Secretary of State';
	end if;
end//

delimiter ;

drop trigger if exists tr_voter_bd;

delimiter //

create trigger tr_voter_bd
	before delete on voter
    for each row
begin
	if user() not like 'secretary_of_state%' then
		signal sqlstate '45000'
        set message_text ='Voters can be deleted only by the Secretary of State';
	end if;
end//

delimiter ;

create table voter_audit
(
	audit_datetime	datetime,
    audit_user	   	varchar(100),
    audit_change	varchar(1000)
	
);

create table ballot_audit
(
	audit_datetime	datetime,
    audit_user		varchar(100),
    audit_change	varchar(1000)
);

create table race_audit
(
	audit_datetime	datetime,
    audit_user	   	varchar(100),
    audit_change	varchar(1000)
	
);

create table candidate_audit
(
	audit_datetime	datetime,
    audit_user		varchar(100),
    audit_change	varchar(1000)
);

create table ballot_candidate_audit
(
	audit_datetime	datetime,
    audit_user		varchar(100),
    audit_change	varchar(1000)
);

drop trigger if exists tr_voter_ai;

delimiter //

create trigger tr_voter_ai
  after insert on voter
   for each row
begin
  insert into voter_audit
  (
    audit_datetime,
    audit_user,
    audit_change
  )
  values
  (
    now(),
    user(),
    concat(
      'New voter added -',
	  ' voter_id: ', 				new.voter_id,
	  ' voter_name: ',				new.voter_name,
	  ' voter_address: ',			new.voter_address,
	  ' voter_county: ',		    new.voter_county,
	  ' voter_district: ',			new.voter_district,
	  ' voter_precinct: ',			new.voter_precinct,
	  ' voter_party: ',				new.voter_party,
	  ' voting_location: ',			new.voting_location,
	  ' voter_registration_num: ',	new.voter_registration_num
    )
  );
end//

delimiter ;

drop trigger if exists tr_voter_ad;

delimiter //

create trigger tr_voter_ad
  after delete on voter
  for each row
begin
  insert into voter_audit
  (
    audit_datetime,
    audit_user,
    audit_change
  )
  values
  (
    now(),
    user(),
    concat(
      'voter deleted -',
	  ' voter_id: ', 				old.voter_id,
	  ' voter_name: ',				old.voter_name,
	  ' voter_address: ',			old.voter_address,
	  ' voter_county: ',		    old.voter_county,
	  ' voter_district: ',			old.voter_district,
	  ' voter_precinct: ',			old.voter_precinct,
	  ' voter_party: ',				old.voter_party,
	  ' voting_location: ',			old.voting_location,
	  ' voter_registration_num: ',	old.voter_registration_num
    )
  );
end//

delimiter ;

drop trigger if exists tr_voter_au;

delimiter //

create trigger tr_voter_au
  after update on voter
  for each row
begin
  set @change_msg = concat('voter ',old.voter_id,' updated');

  if new.voter_id != old.voter_id then
    set @change_msg = concat(@change_msg, concat('. voter_id changed from ', old.voter_id, ' to ', new.voter_id));
  end if;

  if new.voter_name != old.voter_name then
    set @change_msg = concat(@change_msg, concat('. voter_name changed from ', old.voter_name, ' to ', new.voter_name));
  end if;
  
  if new.voter_address != old.voter_address then
    set @change_msg = concat(@change_msg, concat('. voter_address changed from ', old.voter_address, ' to ', new.voter_address));
  end if;

  if new.voter_county != old.voter_county then
    set @change_msg = concat(@change_msg, concat('. voter_county changed from ', old.voter_county, ' to ', new.voter_county));
  end if;
  
  if new.voter_district != old.voter_district then
    set @change_msg = concat(@change_msg, concat('. voter_district changed from ', old.voter_district, ' to ', new.voter_district));
  end if;

  if new.voter_precinct != old.voter_precinct then
    set @change_msg = concat(@change_msg, concat('. voter_precinct changed from ', old.voter_precinct, ' to ', new.voter_precinct));
  end if;

  if new.voter_party != old.voter_party then
    set @change_msg = concat(@change_msg, concat('. voter_party changed from ', old.voter_party, ' to ', new.voter_party));
  end if;

  if new.voting_location != old.voting_location then
    set @change_msg = concat(@change_msg, concat('. voting_location changed from ', old.voting_location, ' to ', new.voting_location));
  end if;  
  
  if new.voter_registration_num != old.voter_registration_num then
    set @change_msg = concat(@change_msg, concat('. voter_registration changed from ', old.voter_registration_num, ' to ', new.voter_registration_num));
  end if;
  
insert into voter_audit(audit_datetime, audit_user, audit_change)   
values (now(), user(), @change_msg);
  
end//

delimiter ;


		   

