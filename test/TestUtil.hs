{-# LANGUAGE ScopedTypeVariables, CPP, FlexibleInstances #-}

module TestUtil
    (runTests
    ,testGen, testRaw
    ,erroneous, erroneousIO
    ,(====)
    ,ASCIIString(..)
    ,module X
    ) where

import Test.QuickCheck
import Test.QuickCheck.Test
import Control.Exception.Extra
import Data.Either.Extra
import System.IO.Extra
import Data.Version.Extra
import Data.IORef
import System.IO.Unsafe
import Text.Show.Functions()

import Extra as X
import Control.Applicative as X
import Control.Monad as X
import Data.Function as X
import Data.List as X
import Data.Char as X
import Data.Monoid as X
import Data.Tuple as X
import Data.Typeable as X
import Data.Version as X
import System.Directory as X
import System.FilePath as X
import System.Info as X
import Control.Exception as X
import Test.QuickCheck as X((==>))


{-# NOINLINE testCount #-}
testCount :: IORef Int
testCount = unsafePerformIO $ newIORef 0

testGen :: Testable prop => String -> prop -> IO ()
testGen msg prop = testRaw msg $ do
    r <- quickCheckResult prop
    unless (isSuccess r) $ error "Test failed"

testRaw :: String -> IO () -> IO ()
testRaw msg test = do
    putStrLn msg
    test
    modifyIORef testCount (+1)


erroneous :: Show a => a -> Bool
erroneous x = unsafePerformIO $ fmap isLeft $ try_ $ evaluate $ length $ show x

erroneousIO :: Show a => IO a -> Bool
erroneousIO x = unsafePerformIO $ fmap isLeft $ try_ $ evaluate . length . show =<< x

(====) :: (Show a, Eq a) => a -> a -> Bool
a ==== b
    | a == b = True
    | otherwise = error $ "Not equal!\n" ++ show a ++ "\n" ++ show b

#if __GLASGOW_HASKELL__ < 707
instance Eq ErrorCall where
    ErrorCall x == ErrorCall y = x == y
#endif

runTests :: IO () -> IO ()
runTests t = do
    writeIORef testCount 0
    t
    n <- readIORef testCount
    putStrLn $ "Success (" ++ show n ++ " tests)"

instance Testable a => Testable (IO a) where
    property = property . unsafePerformIO

instance Eq a => Eq (IO a) where
    a == b = unsafePerformIO $ do
        a <- try_ $ captureOutput a
        b <- try_ $ captureOutput b
        return $ a == b

instance Show (IO a) where
    show _ = "<<IO>>"

instance Arbitrary a => Arbitrary (IO a) where
    arbitrary = do
        (prnt :: Maybe Int, thrw :: Maybe Int, res) <- arbitrary
        return $ do
            whenJust prnt print
            whenJust thrw (fail . show)
            return res

instance Eq SomeException where
    a == b = show a == show b
