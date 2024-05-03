USE ipl;

-- 1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage

With status_bidCTE as(
    Select bidder_id, bid_status,
        Case
            When bid_status = 'Won' then 1
            else 0
            end as status_bid
	from  ipl_bidding_details
    )
select bidder_id, round((sum(status_bid)/count(bid_status)),2)*100 as percentage_of_wins 
from status_bidCTE
group by bidder_id
order by round((sum(status_bid)/count(bid_status)),2)*100 desc;

-- insights -- It can be observed that 3 bidders (109,102,116) has 0% win whereas only one bidder (103) has a 100% record win.

-- 2.	Display the number of matches conducted at each stadium with the stadium name and city.

select ms.stadium_id, count(match_id) as no_of_matches, stadium_name, city 
from ipl_match_schedule ms
join ipl_stadium s
using(stadium_id)
group by stadium_name, city, ms.stadium_id
order by count(match_id) desc;

-- insights -- Wankhede Stadium of Mumbai had the highest no. of matches held where as Rajiv Gandhi International stadium of Hyderabad had the least. 

-- 3. In a given stadium, what is the percentage of wins by a team that has won the toss?

WITH winner_idCTE AS (
    SELECT 
        CASE
            WHEN (toss_winner = match_winner) AND (toss_winner = 1) THEN team_id1
            WHEN (toss_winner = match_winner) AND (toss_winner = 2) THEN team_id2
            ELSE NULL
        END AS winner_id
    FROM ipl_match
),
no_of_matches_query AS (
    SELECT 
        team_id1,
        (COUNT(team_id1) + COUNT(team_id2)) AS no_of_matches 
    FROM ipl_match 
    GROUP BY team_id1
)
SELECT 
    winner_id,
    (COUNT(winner_id)/no_of_matches)*100 AS percentage_of_wins
FROM winner_idCTE 
JOIN no_of_matches_query ON winner_id = team_id1
GROUP BY winner_id
order by (COUNT(winner_id)/no_of_matches)*100 desc;

-- insights --

-- 4.	Show the total bids along with the bid team and team name.

select distinct bid_team, sum(no_of_bids) as total_bids, team_name
from ipl_bidder_points ibp 
join ipl_bidding_details ipd
using(bidder_id)
join ipl_team it
on ipd.bid_team = it.team_id
group by 1,3;

-- insights --

-- 5.	Show the team ID who won the match as per the win details.


with win_detailsCTE as(
    Select match_id, win_details,
        Case
            When match_winner = 1 then team_id1
            when match_winner = 2 then team_id2 
            else null
            end as team_id_won
	from ipl_match
)
select * from win_detailsCTE;

-- 6.	Display the total matches played, total matches won and total matches lost by the team along with its team name.

Select tournmt_id, matches_played, matches_won, matches_lost, team_name 
from ipl_team_standings
join ipl_team
using(team_id)
order by tournmt_id asc;

-- insights -- Highest wins in 2017 was that of CSK and in 2018 it was that of MI.

-- 7.	Display the bowlers for the Mumbai Indians team.

SELECT player_name 
FROM ipl_player 
WHERE player_id IN (
    SELECT player_id 
    FROM ipl_team_players 
    WHERE(player_role = 'bowler') AND (team_id IN (
        SELECT TEAM_ID 
        FROM IPL_TEAM
        WHERE TEAM_NAME = 'Mumbai Indians')));
        
-- 8.	How many all-rounders are there in each team, Display the teams with more than 4 all-rounders in descending order.

Select team_id, count(player_role) as no_of_all_rounders, team_name
from ipl_team_players
join ipl_team
using(team_id)
where(player_role = 'All-Rounder')
group by team_id
having (count(player_role) > 4)
order by count(player_role) desc;

-- insights -- Delhi Daredevils has the highest no of all rounders in their team.

-- 9.	 Write a query to get the total bidders' points for each bidding status of those bidders who bid on CSK when they won the match in M. 
-- Chinnaswamy Stadium bidding year-wise.
--  Note the total bidders’ points in descending order and the year is the bidding year.
--  Display columns: bidding status, bid date as year, total bidder’s points

Select bid_status, year(Bid_date) as Bid_year, total_points as bidder_points
from ipl_bidding_details
join ipl_bidder_points
using(bidder_id)
where bid_team in (
    Select team_id from ipl_team where team_name = 'Chennai Super Kings')
    and schedule_id in (
        Select schedule_id from ipl_match_schedule where stadium_id in (
            Select stadium_id from ipl_stadium where stadium_name = 'M. Chinnaswamy Stadium'))
	and schedule_id in (
        Select schedule_id from ipl_match_schedule where match_id in (
            Select match_id from ipl_match where win_details like 'Team CSK won%'))
order by year(Bid_date) asc;

-- 10.	Extract the Bowlers and All-Rounders that are in the 5 highest number of wickets.
-- Note 
-- 1. Use the performance_dtls column from ipl_player to get the total number of wickets
--  2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
-- 3.	Do not use joins in any cases.
-- 4.	Display the following columns teamn_name, player_name, and player_role.
Select * from ipl_player;

WITH WicketCTE AS (
    SELECT player_id, player_name,
        CAST(REPLACE(SUBSTRING(performance_dtls, LOCATE('Wkt-', performance_dtls) + 3, 
        LOCATE(' ', performance_dtls, LOCATE('Wkt-', performance_dtls)) - (LOCATE('Wkt-', performance_dtls) + 3)), '-', '') AS SIGNED) AS Wickets
    FROM 
        ipl_player
)
SELECT * FROM WicketCTE
WHERE player_id IN (
    SELECT player_id FROM ipl_team_players WHERE player_role IN ('Bowler', 'All-Rounder'))
ORDER BY Wickets DESC;

-- insights --

-- 11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

WITH toss_winner_detailsCTE AS (
    SELECT team_id1,
        CASE
            WHEN toss_winner = 1 THEN team_id1
            WHEN toss_winner = 2 THEN team_id2 
            ELSE NULL
        END AS team_won_toss
    FROM ipl_match
),
toss_winner_countCTE AS (
    SELECT team_id1 AS team_id_winning_toss, COUNT(team_won_toss) AS toss_win_counts
    FROM toss_winner_detailsCTE
    GROUP BY 1
)
SELECT 
    ibd.bidder_id,
    (COUNT(twc.team_won_toss)/sum(no_of_bids))*100 as percentage_of_toss_wins
FROM 
    toss_winner_detailsCTE twc
JOIN 
    toss_winner_countCTE twcc ON twc.team_id1 = twcc.team_id_winning_toss
JOIN 
    ipl_bidding_details ibd ON ibd.bid_team = twc.team_id1
JOIN 
    ipl_bidder_points ibp ON ibd.bidder_id = ibp.bidder_id
GROUP BY 
    ibd.bidder_id;
    
-- 12.	find the IPL season which has a duration and max duration.Output columns should be like the below: Tournment_ID, Tourment_name, Duration column, Duration

WITH TournamentDuration AS (
    SELECT tournmt_id,
        MIN(match_date) AS start_date,
        MAX(match_date) AS end_date,
        TIMESTAMPDIFF(DAY, MIN(match_date), MAX(match_date)) AS duration
    FROM ipl_match_schedule
    GROUP BY tournmt_id
)
SELECT tournmt_id, tournmt_name, CONCAT(duration, ' days') AS Duration_Column
FROM TournamentDuration
JOIN ipl_tournament
USING (tournmt_id)
WHERE duration IS NOT NULL
ORDER BY duration DESC;

-- 13.	Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order 
-- and month-wise in ascending order.
-- Note: Display the following columns:
-- 1.	Bidder ID, 2. Bidder Name, 3. Bid date as Year, 4. Bid date as Month, 5. Total points
-- Only use joins for the above query queries.

SELECT 
    ibd.bidder_id,
    bidder_name,
    YEAR(Bid_date) AS Year,
    MONTH(Bid_date) AS Month,
    SUM(Total_points) AS Total_Points
FROM 
    ipl_bidding_details ibd
JOIN 
    ipl_bidder_details ibdet ON ibd.bidder_id = ibdet.bidder_id
JOIN 
    ipl_bidder_points ibp ON ibd.bidder_id = ibp.bidder_id
WHERE 
    YEAR(ibd.Bid_date) = 2017
GROUP BY 
    ibd.bidder_id, 
    YEAR(ibd.Bid_date),
    MONTH(ibd.Bid_date)
ORDER BY 
    Total_Points DESC, 
    YEAR(ibd.Bid_date),
    MONTH(ibd.Bid_date);
    
-- 14.	Write a query for the above question using sub-queries by having the same constraints as the above question.
    
SELECT 
    ibdet.bidder_id,
    ibdet.bidder_name,
    YEAR(ibd.Bid_date) AS Year,
    MONTH(ibd.Bid_date) AS Month,
    (
        SELECT 
            SUM(ibp.Total_points) 
        FROM 
            ipl_bidder_points ibp 
        WHERE 
            ibp.bidder_id = ibd.bidder_id
    ) AS Total_Points
FROM 
    ipl_bidding_details ibd
JOIN 
    ipl_bidder_details ibdet ON ibd.bidder_id = ibdet.bidder_id
WHERE 
    YEAR(ibd.Bid_date) = 2017
GROUP BY 
    ibd.bidder_id, 
    YEAR(ibd.Bid_date),
    MONTH(ibd.Bid_date)
ORDER BY 
    Total_Points DESC, 
    YEAR(ibd.Bid_date),
    MONTH(ibd.Bid_date);
    
-- 15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
-- Output columns should be: like
-- Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder;

WITH BidderPoints AS (
    SELECT
        bp.bidder_id,
        SUM(total_points) AS total_points
    FROM
        ipl_bidder_points bp 
    JOIN 
        ipl_bidding_details bd ON bp.bidder_id = bd.bidder_id
    WHERE
        YEAR(bd.bid_date) = 2018
    GROUP BY
        bp.bidder_id
), 
RankedBidderPoints AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY total_points DESC) AS Rank_,
        bidder_id,
        total_points
    FROM
        BidderPoints
)
SELECT
    * ,
    CASE
        WHEN Rank_ <= 3 THEN bd.bidder_name
    END AS Highest_3_Bidders,
    CASE
        WHEN Rank_ > (SELECT COUNT(*) FROM BidderPoints) - 3 THEN bd.bidder_name
    END AS Lowest_3_Bidders
FROM
    RankedBidderPoints rbp
JOIN
    ipl_bidder_details bd ON rbp.bidder_id = bd.bidder_id
GROUP BY
    Rank_, bp.bidder_id
ORDER BY
    total_points DESC;

-- 16.	Create two tables called Student_details and Student_details_backup. (Additional Question - Self Study is required)

-- Table 1: Attributes 		Table 2: Attributes
-- Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.


-- Create Student_details table
CREATE TABLE Student_details (
    Student_id INT PRIMARY KEY,
    Student_name VARCHAR(255),
    Mail_id VARCHAR(255),
    Mobile_no VARCHAR(15)
);

-- Create Student_details_backup table
CREATE TABLE Student_details_backup (
    Student_id INT PRIMARY KEY,
    Student_name VARCHAR(255),
    Mail_id VARCHAR(255),
    Mobile_no VARCHAR(15)
);

-- Create trigger to insert into Student_details_backup
DELIMITER //
CREATE TRIGGER Insert_Student_backup
AFTER INSERT ON Student_details
FOR EACH ROW
BEGIN
    INSERT INTO Student_details_backup (Student_id, Student_name, Mail_id, Mobile_no)
    VALUES (NEW.Student_id, NEW.Student_name, NEW.Mail_id, NEW.Mobile_no);
END;
//
DELIMITER ;