{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Pahket.AHK
  ( run,
    exampleProgram,
  )
where

import Pahket.Core
import qualified Pahket.Core.Config as Config
import qualified System.IO as IO
import qualified System.IO.Temp as Temp

run ::
  MonadReader (Env m) m =>
  WithLog env Message m =>
  MonadMask m =>
  MonadIO m =>
  m ()
run = Temp.withSystemTempFile "pahket.ahk" $ \filepath hnd -> do
  logDebug "Cloning dependencies"
  maybeConfig <- asks envProjectConfig
  let config = maybeConfig ?: error "No project config found, have you created a 'pahket.toml' file?"
  forM_ (Config.dependencies config) $ \(Config.Dependency name git) ->
    runProcess_ $ proc "git" ["clone", toString git, "lib\\" <> toString name]
  logDebug "Getting input file name from env"
  inputFile <- asks envInputFile
  port <- asks envServerPort
  logDebug "Reading input file"
  contents <- readFileText inputFile
  logDebug "Preparing and saving to temporary file"
  liftIO $ IO.hPutStrLn hnd (toString $ preparePahket port contents)
  logDebug "Flushing file"
  liftIO $ IO.hFlush hnd
  let ahk = "C:\\Program Files\\AutoHotkey\\AutoHotkey.exe"
  let args = ["/ErrorStdOut", filepath, "2>&1", "|more"]
  logDebug ("Spawning AutoHotkey with path " <> show ahk <> " and args " <> show args)
  (_, _, err) <- readProcess $ proc ahk args
  when (err /= "") $ do
    logDebug "Printing STDERR"
    putLBSLn err
    serverSemaphore <- asks envServerSemaphore
    liftIO $ signalQSem serverSemaphore

preparePahket :: Int -> Text -> Text
preparePahket port script =
  [i|
  #NoTrayIcon
  global __PahketBaseURL__ := "http://localhost:" . "#{show port :: Text}"
  try {
  #{includeJxon}
  #{includeInterop}
  #{includeStdLib}
  #{script}
  } catch e {
    print(e)
  }
  __Pahket__.exitServer()
  |]
  where
    includeJxon = $(embedStringFile "ahk/Jxon.ahk") :: Text
    includeInterop = $(embedStringFile "ahk/Interop.ahk") :: Text
    includeStdLib = $(embedStringFile "ahk/StdLib.ahk") :: Text

exampleProgram :: Text
exampleProgram =
  [i|
print("hello")
print("hello1")
print("hello2")
print("hello3")
|]
