module Pahket
  ( run,
    runWithEnv,
  )
where

import Control.Concurrent (forkIO)
import qualified Pahket.AHK as AHK
import Pahket.Core
import qualified Pahket.Core.Init as Init
import qualified Pahket.Finisher as Finisher
import qualified Pahket.Server as Server

run :: IO ()
run = do
  env <- Init.env
  runWithEnv env

runWithEnv :: Env App -> IO ()
runWithEnv env = do
  serverThreadId <- forkIO $ runApp env $ do
    logDebug "Starting server"
    _ <- liftIO $ Server.run env
    logDebug "Running AHK app"
    AHK.run
  runApp env $ do
    logDebug "Starting finisher"
    liftIO $ Finisher.run env serverThreadId
    logDebug "Bye"
