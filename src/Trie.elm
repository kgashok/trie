module Trie
  ( Trie(..)
  , empty
  , add
  , remove
  , has
  , get
  , getNode
  , valueCount
  , expand
  , getValues
  ) where

{-| A Trie data structure.

Copyright (c) 2016 Robin Luiten

A trie is an ordered tree data structure that is used to store a dynamic
set or associative array where the keys are usually strings.

In this implementation they key is a String.

In this implementation unique reference stored in the value
dictionary for a given key is a String.

## Data Model
@docs Trie

## Create
@docs empty

## Modify
@docs add
@docs remove

## Query
@docs has
@docs get
@docs getNode
@docs valueCount
@docs expand

## Get data values from node
@docs getValues

-}

import Dict exposing (Dict)
import List
import Maybe exposing (withDefault, andThen)
import String


{-| Trie data model definition.
-}
type Trie a
    = EmptyTrie
    | ValNode (Dict String a)
    | TrieNode (Dict Char (Trie a))
    | ValTrieNode (Dict String a) (Dict Char (Trie a))


{-| An empty Trie -}
empty : Trie a
empty = EmptyTrie


{-| Returns True if Trie is empty -}
isEmpty : Trie a -> Bool
isEmpty trie =
    trie == empty


{-| Add reference and values with key to Trie.

```
updatedTrie = Trie.add ("refid123", ("ValueStored", 42.34)) "someword" Trie.empty
```
-}
add : (String, a) -> String -> Trie a -> Trie a
add refValues key trie =
    addByChars refValues (String.toList key) trie


{-| see add
-}
addByChars : (String, a) -> List Char -> Trie a -> Trie a
addByChars (ref, value) key trie =
    case key of
      [] ->
        case trie of
          EmptyTrie ->
            ValNode (Dict.singleton ref value)

          ValNode refValues ->
            ValNode (Dict.insert ref value  refValues)

          TrieNode trieDict ->
            ValTrieNode (Dict.singleton ref value) trieDict

          ValTrieNode refValues trieDict ->
            ValTrieNode (Dict.insert ref value  refValues) trieDict

      keyHead :: keyTail ->
        let
          lazyNewTrieDict =
              (\_ ->
                addByChars (ref, value) keyTail EmptyTrie
                  |> Dict.singleton keyHead
              )

          updateTrieDict trieDict =
            let
              updatedSubTrie =
                Dict.get keyHead trieDict
                  |> withDefault EmptyTrie
                  |> addByChars (ref, value) keyTail
            in
              Dict.insert keyHead updatedSubTrie trieDict
        in
          case trie of
            EmptyTrie ->
              TrieNode (lazyNewTrieDict ())

            ValNode refValues ->
              ValTrieNode refValues (lazyNewTrieDict ())

            TrieNode trieDict ->
              TrieNode (updateTrieDict trieDict)

            ValTrieNode refValues trieDict ->
              ValTrieNode refValues (updateTrieDict trieDict)

{-| Remove values for key and reference from Trie.

This removes the reference from the correct values list.
If the key does not exist nothing changes.
If the ref is not found in the values for the key nothing changes.

An example but does not do anything.
```
updatedTrie = Trie.remove "for" "refid125" Trie.empty
```


Add something then remove it.
```
trie1 = Trie.add ("refid123", ("ValueStored", 42.34)) "someword" Trie.empty

trie2 = Trie.remove "someword" "refid123" Trie.trie1
```

-}
remove : String -> String -> Trie a -> Trie a
remove key ref trie =
    removeByChars (String.toList key) ref trie


{-| see remove
-}
removeByChars : List Char -> String -> Trie a -> Trie a
removeByChars key ref trie =
    case key of
      [] ->
        case trie of
          EmptyTrie ->
            trie

          ValNode refValues ->
            ValNode (Dict.remove ref refValues)

          TrieNode trieDict ->
            trie

          ValTrieNode refValues trieDict ->
            ValTrieNode (Dict.remove ref refValues) trieDict

      keyHead :: keyTail ->
        let
          removeTrieDict trieDict =
              case (Dict.get keyHead trieDict) of
                Nothing ->
                  trieDict

                Just subTrie ->
                  Dict.insert keyHead (removeByChars keyTail ref subTrie) trieDict
        in
          case trie of
            EmptyTrie ->
              trie

            ValNode refValues ->
              trie

            TrieNode trieDict ->
              TrieNode (removeTrieDict trieDict)

            ValTrieNode refValues trieDict ->
              ValTrieNode refValues (removeTrieDict trieDict)

{-| Return Trie node if found.

This will return Nothing.
```
maybeNode = Trie.getNode "for" Trie.empty
```

This will the node containing the values for the word "someword".
It will contains "refid123" in the dictionary point at  ("ValueStored", 42.34).
```
trie1 = Trie.add ("refid123", ("ValueStored", 42.34)) "someword" Trie.empty

maybeNode = Trie.getNode "someword" trie1
```

-}
getNode : String -> Trie a -> Maybe (Trie a)
getNode key trie =
    getNodeByChars (String.toList key) trie


{-| see getNode
-}
getNodeByChars : List Char -> Trie a -> Maybe (Trie a)
getNodeByChars key trie =
    if List.isEmpty key then
      Nothing
    else
      getNodeCore key trie


getNodeCore : List Char -> Trie a -> Maybe (Trie a)
getNodeCore key trie =
    case key of
      [] ->
        Just trie

      keyHead :: keyTail ->
        let
          getTrie trieDict =
            (Dict.get keyHead trieDict) `andThen`
              (getNodeCore keyTail)
        in
          case trie of
            EmptyTrie ->
              Nothing

            ValNode _ ->
              Nothing

            TrieNode trieDict ->
              getTrie trieDict

            ValTrieNode _ trieDict ->
              getTrie trieDict


{-| Checks whether key is contained within a Trie.

A key must have values for it be considered present in Trie.
-}
has : String -> Trie a -> Bool
has key trie =
    hasByChars (String.toList key) trie


{-| see has
-}
hasByChars : List Char -> Trie a -> Bool
hasByChars key trie =
    (getNodeByChars key trie) `andThen` getValues
      |> withDefault Dict.empty
      |> not << Dict.isEmpty


{-| Return values for a key if found.
-}
get : String -> Trie a -> Maybe (Dict String a)
get key trie =
    getByChars (String.toList key) trie


{-| see get
-}
getByChars : List Char -> Trie a -> Maybe (Dict String a)
getByChars key trie =
    (getNodeByChars key trie) `andThen` getValues


{-| Return the values stored if there are any
-}
getValues : Trie a -> Maybe (Dict String a)
getValues trie =
    case trie of
      EmptyTrie ->
        Nothing

      ValNode refValues ->
        Just refValues

      TrieNode _ ->
        Nothing

      ValTrieNode refValues _ ->
        Just refValues


{-| Return number of values stored at Trie location.
-}
valueCount : String -> Trie a -> Int
valueCount key trie =
    Dict.size (withDefault Dict.empty (get key trie))


{-| see valueCount
-}
valueCountByChars : List Char -> Trie a -> Int
valueCountByChars key trie =
    Dict.size (withDefault Dict.empty (getByChars key trie))


{-| Find all the possible suffixes of the passed key using keys
currently in the store.

This returns a List of all keys from starting key down.
The definition of a key that exists is one that has documents defined for it.

Given this setup
```
    trie1 = Trie.add ("refid121", 1) "ab" Trie.empty
    trie2 = Trie.add ("refid122", 2) "ac" trie1
    trie3 = Trie.add ("refid123", 3) "acd" trie2
```

This
```
    Trie.expand "a" trie3
```
Returns
```
["ab","acd","ac"]
```


This
```
    Trie.expand "ac" trie3
```
Returns
```
["acd","ac"]
```

-}
expand : String -> Trie a-> List String
expand key trie =
    expandByChars (String.toList key) trie


{-| see expand
-}
expandByChars : List Char -> Trie a -> List String
expandByChars key trie  =
    case getNodeByChars key trie of
      Nothing ->
        []

      Just keyTrie ->
        expandCore key keyTrie []


expandCore : List Char -> Trie a -> List String -> List String
expandCore key trie keyList =
    let
      addRefKey refValues =
        if not (Dict.isEmpty refValues) then
          (String.fromList key) :: keyList
        else
          keyList
      expandSub char trie foldList =
        expandCore (key ++ [ char ]) trie foldList
    in
      case trie of
        EmptyTrie ->
          keyList

        ValNode refValues ->
          addRefKey refValues

        TrieNode trieDict ->
          Dict.foldr expandSub keyList trieDict

        ValTrieNode refValues trieDict ->
          let
            dirtyList = addRefKey refValues
          in
            Dict.foldr expandSub dirtyList trieDict
