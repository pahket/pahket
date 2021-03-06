module Pahket
  ( run,
  )
where

import qualified Pahket.Commands.Help as Help
import qualified Pahket.Commands.Install as Install
import qualified Pahket.Commands.Version as Version

run :: [String] -> IO ()
run ("version" : _) = Version.run
run ("install" : _) = Install.run
run _ = Help.run
