-- Donor Lifecycle & Fundraising Campaign Optimization System Project
-- Creates the five tables (channels, campaigns, donors, gifts and marketing spend) in Oracle
-- =====================================================================

BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('GIFTS','DONORS','CAMPAIGNS','MARKETING_SPEND','CHANNELS')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

CREATE TABLE channels (
  channel_id    NUMBER(3)     PRIMARY KEY,
  channel_name  VARCHAR2(50)  NOT NULL
);

CREATE TABLE campaigns (
  campaign_id    NUMBER(6)     PRIMARY KEY,
  campaign_name  VARCHAR2(100) NOT NULL,
  program_area   VARCHAR2(50),
  campaign_year  NUMBER(4)
);

CREATE TABLE donors (
  donor_id               NUMBER(8)    PRIMARY KEY,
  first_name             VARCHAR2(50),
  last_name              VARCHAR2(50),
  donor_type             VARCHAR2(30),
  state                  CHAR(2),
  email_opt_in           NUMBER(1),
  grateful_patient       NUMBER(1),
  acquisition_channel_id NUMBER(3) REFERENCES channels(channel_id),
  first_gift_date        DATE
);

CREATE TABLE gifts (
  gift_id        NUMBER(10)    PRIMARY KEY,
  donor_id       NUMBER(8)     NOT NULL REFERENCES donors(donor_id),
  gift_date      DATE          NOT NULL,
  gift_amount    NUMBER(12,2)  NOT NULL,
  channel_id     NUMBER(3)     REFERENCES channels(channel_id),
  campaign_id    NUMBER(6)     REFERENCES campaigns(campaign_id),
  payment_method VARCHAR2(20),
  is_recurring   NUMBER(1)
);

CREATE TABLE marketing_spend (
  spend_month   DATE          NOT NULL,
  channel_id    NUMBER(3)     NOT NULL REFERENCES channels(channel_id),
  spend_amount  NUMBER(12,2)  NOT NULL,
  CONSTRAINT pk_spend PRIMARY KEY (spend_month, channel_id)
);

CREATE INDEX ix_gifts_donor ON gifts(donor_id);
CREATE INDEX ix_gifts_date  ON gifts(gift_date);
CREATE INDEX ix_gifts_chan  ON gifts(channel_id);