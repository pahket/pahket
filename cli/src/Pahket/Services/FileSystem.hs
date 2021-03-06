module Pahket.Services.FileSystem
  ( Service (..),
    Access (..),
    new,
  )
where

import qualified Path
import qualified Path.IO as PathIO

data Service
  = Service
      { listAllFiles :: forall env. FilePath -> RIO env [FilePath],
        readFile :: forall env. FilePath -> RIO env Text,
        doesDirExist :: forall env. FilePath -> RIO env Bool,
        renameFile :: forall env. FilePath -> FilePath -> RIO env ()
      }

class Access env where
  access :: Lens' env Service

instance Access Service where
  access = id

new :: IO Service
new =
  pure $
    Service
      { listAllFiles = listAllFilesImpl,
        readFile = readFileImpl,
        doesDirExist = doesDirExistImpl,
        renameFile = renameFileImpl
      }

listAllFilesImpl :: FilePath -> RIO env [FilePath]
listAllFilesImpl filepath = do
  dir <- Path.parseRelDir filepath
  (_, allFiles) <- PathIO.listDirRecur dir
  pure (fmap Path.fromAbsFile allFiles)

readFileImpl :: FilePath -> RIO env Text
readFileImpl = readFileUtf8

doesDirExistImpl :: FilePath -> RIO env Bool
doesDirExistImpl fp = do
  dir <- Path.parseRelDir fp
  PathIO.doesDirExist dir

renameFileImpl :: FilePath -> FilePath -> RIO env ()
renameFileImpl source destination = do
  src <- Path.parseAbsFile source
  dest <- Path.parseRelFile destination
  PathIO.renameFile src dest
