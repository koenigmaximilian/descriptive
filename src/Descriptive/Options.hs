{-# LANGUAGE TupleSections #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}

-- | Command-line options parser.

module Descriptive.Options where

import           Data.List
import           Data.Monoid
import           Data.Text (Text)
import qualified Data.Text as T
import           Descriptive

data Option
  = AnyString !Text
  | Constant !Text
  | Flag !Text !Text
  | Arg !Text !Text
  | Prefix !Text !Text
  deriving (Show)

-- | Consume one argument from the argument list.
anyString :: Text -> Consumer [Text] Option Text
anyString help =
  consumer (d,)
           (\s ->
              case s of
                [] -> (Left d,s)
                (x:s') -> (Right x,s'))
  where d = Unit (AnyString help)

-- | Consume one argument from the argument list.
constant :: Text -> Consumer [Text] Option Text
constant x' =
  consumer (d,)
           (\s ->
              case s of
                (x:s') | x == x' ->
                  (Right x,s')
                _ -> (Left d,s))
  where d = Unit (Constant x')

-- | Find a short boolean flag.
flag :: Text -> Text -> Consumer [Text] Option Bool
flag name help =
  consumer (d,)
           (\s ->
              (Right (elem ("-f" <> name) s),s))
  where d = Unit (Flag name help)

-- | Find an argument prefixed by -X.
prefix :: Text -> Text -> Consumer [Text] Option Text
prefix prefix help =
  consumer (d,)
           (\s ->
              case find (T.isPrefixOf ("-" <> prefix)) s of
                Nothing -> (Left d,s)
                Just rest -> (Right rest,s))
  where d = Unit (Prefix prefix help)

-- | Find a named argument.
arg :: Text -> Text -> Consumer [Text] Option Text
arg name help =
  consumer (d,)
           (\s ->
              let indexedArgs =
                    zip [0 :: Integer ..] s
              in case find ((== "--" <> name) . snd) indexedArgs of
                   Nothing -> (Left d,s)
                   Just (i,_) ->
                     case lookup (i + 1) indexedArgs of
                       Nothing -> (Left d,s)
                       Just text ->
                         (Right text,s))
  where d = Unit (Arg name help)
