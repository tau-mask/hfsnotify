--
-- Copyright (c) 2012 Mark Dittmer - http://www.markdittmer.org
-- Developed for a Google Summer of Code project - http://gsoc2012.markdittmer.org
--

module System.FSNotify.Types
       ( act
       , ActionPredicate
       , Action
       , WatchConfig(..)
       , WatchMode(..)
       , ThreadingMode(..)
       , Event(..)
       , EventIsDirectory(..)
       , EventCallback
       , EventChannel
       , EventAndActionChannel
       , IOEvent
       ) where

import Control.Concurrent.Chan
import Control.Exception.Safe
import Data.IORef (IORef)
import Data.Time.Clock (UTCTime)
import Prelude hiding (FilePath)
import System.FilePath

data EventIsDirectory = IsFile | IsDirectory
  deriving (Show, Eq)

-- | A file event reported by a file watcher. Each event contains the
-- canonical path for the file and a timestamp guaranteed to be after the
-- event occurred (timestamps represent current time when FSEvents receives
-- it from the OS and/or platform-specific Haskell modules).
data Event =
    Added { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory }
  | Modified { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory }
  | ModifiedAttributes { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory }
  | Removed { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory }
  | WatchedDirectoryRemoved  { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory }
  -- ^ Note: currently only emitted on Linux
  | CloseWrite  { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory }
  -- ^ Note: currently only emitted on Linux
  | Unknown  { eventPath :: FilePath, eventTime :: UTCTime, eventIsDirectory :: EventIsDirectory, eventString :: String }
  -- ^ Note: currently only emitted on Linux
  deriving (Eq, Show)

type EventChannel = Chan Event

type EventCallback = Event -> IO ()

type EventAndActionChannel = Chan (Event, Action)

-- | Method of watching for changes.
data WatchMode =
  WatchModeOS
  -- ^ Use OS-specific mechanisms to be notified of changes (inotify on Linux, FSEvents on OSX, etc.)
  | WatchModePoll { watchModePollInterval :: Int }
  -- ^ Detect changes by polling the filesystem. Less efficient and may miss fast changes. Not recommended
  -- unless you're experiencing problems with 'WatchModeOS'.

data ThreadingMode =
  SingleThread
  -- ^ Use a single thread for the entire 'Manager'. Event handler callbacks will run sequentially.
  | ThreadPerWatch
  -- ^ Use a single thread for each watch (i.e. each call to 'watchDir', 'watchTree', etc.).
  -- Callbacks within a watch will run sequentially but callbacks from different watches may be interleaved.
  | ThreadPerEvent
  -- ^ Launch a separate thread for every event handler.

-- | Watch configuration
data WatchConfig = WatchConfig
  { confWatchMode :: WatchMode
    -- ^ Watch mode to use
  , confThreadingMode :: ThreadingMode
    -- ^ Threading mode to use
  , confOnHandlerException :: SomeException -> IO ()
    -- ^ Called when a handler throws an exception
  }

type IOEvent = IORef Event

-- | A predicate used to determine whether to act on an event.
type ActionPredicate = Event -> Bool

-- | An action to be performed in response to an event.
type Action = Event -> IO ()

-- | Predicate to always act.
act :: ActionPredicate
act _ = True
