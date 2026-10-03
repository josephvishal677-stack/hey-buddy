
-- ============================================================
-- HEY BUDDY — Social Media Platform Database Schema
-- Engine: MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS heybuddy
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE heybuddy;

-- ------------------------------------------------------------
-- USERS
-- ------------------------------------------------------------
CREATE TABLE users (
  user_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username        VARCHAR(20)  NOT NULL UNIQUE,
  email           VARCHAR(255) NOT NULL UNIQUE,
  password_hash   VARCHAR(255) NOT NULL,
  display_name    VARCHAR(50)  NULL,
  bio             VARCHAR(150) NULL,
  avatar_url      VARCHAR(500) NULL,
  is_private      BOOLEAN NOT NULL DEFAULT FALSE,
  is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_username CHECK (CHAR_LENGTH(username) >= 3)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- POSTS
-- ------------------------------------------------------------
CREATE TABLE posts (
  post_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      BIGINT UNSIGNED NOT NULL,
  caption      VARCHAR(2200) NULL,
  media_url    VARCHAR(500) NULL,
  media_type   ENUM('image','video','text') NOT NULL DEFAULT 'text',
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_posts_user_created (user_id, created_at),
  INDEX idx_posts_created (created_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- STORIES (expire after 24h — enforced at application layer)
-- ------------------------------------------------------------
CREATE TABLE stories (
  story_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      BIGINT UNSIGNED NOT NULL,
  media_url    VARCHAR(500) NULL,
  text_content VARCHAR(500) NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at   TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_stories_user_expires (user_id, expires_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- FOLLOWS  (also carries pending follow-requests for private accounts)
-- ------------------------------------------------------------
CREATE TABLE follows (
  follower_id  BIGINT UNSIGNED NOT NULL,
  followee_id  BIGINT UNSIGNED NOT NULL,
  status       ENUM('pending','accepted') NOT NULL DEFAULT 'accepted',
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (follower_id, followee_id),
  FOREIGN KEY (follower_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (followee_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT chk_no_self_follow CHECK (follower_id <> followee_id),
  INDEX idx_follows_followee (followee_id, status)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- LIKES (polymorphic over posts/stories via target_type)
-- ------------------------------------------------------------
CREATE TABLE likes (
  like_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id      BIGINT UNSIGNED NOT NULL,
  target_type  ENUM('post','story') NOT NULL,
  target_id    BIGINT UNSIGNED NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY uq_like (user_id, target_type, target_id),
  INDEX idx_likes_target (target_type, target_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- COMMENTS
-- ------------------------------------------------------------
CREATE TABLE comments (
  comment_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  post_id      BIGINT UNSIGNED NOT NULL,
  user_id      BIGINT UNSIGNED NOT NULL,
  body         VARCHAR(500) NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_comments_post_created (post_id, created_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- SAVED POSTS
-- ------------------------------------------------------------
CREATE TABLE saved_posts (
  user_id      BIGINT UNSIGNED NOT NULL,
  post_id      BIGINT UNSIGNED NOT NULL,
  saved_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, post_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- HASHTAGS
-- ------------------------------------------------------------
CREATE TABLE hashtags (
  hashtag_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tag          VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE post_hashtags (
  post_id      BIGINT UNSIGNED NOT NULL,
  hashtag_id   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (post_id, hashtag_id),
  FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
  FOREIGN KEY (hashtag_id) REFERENCES hashtags(hashtag_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- DIRECT MESSAGES
-- ------------------------------------------------------------
CREATE TABLE conversations (
  conversation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_a_id       BIGINT UNSIGNED NOT NULL,
  user_b_id       BIGINT UNSIGNED NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_a_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (user_b_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE KEY uq_conversation_pair (user_a_id, user_b_id),
  CONSTRAINT chk_distinct_users CHECK (user_a_id <> user_b_id)
) ENGINE=InnoDB;

CREATE TABLE messages (
  message_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_id       BIGINT UNSIGNED NOT NULL,
  body            VARCHAR(2000) NOT NULL,
  sent_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at         TIMESTAMP NULL,
  FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_messages_conv_sent (conversation_id, sent_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- NOTIFICATIONS
-- ------------------------------------------------------------
CREATE TABLE notifications (
  notification_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recipient_id     BIGINT UNSIGNED NOT NULL,
  actor_id         BIGINT UNSIGNED NOT NULL,
  type             ENUM('like','comment','follow','follow_request','mention') NOT NULL,
  target_type      ENUM('post','story','comment','user') NULL,
  target_id        BIGINT UNSIGNED NULL,
  is_read          BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (actor_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_notif_recipient_created (recipient_id, created_at)
) ENGINE=InnoDB;
