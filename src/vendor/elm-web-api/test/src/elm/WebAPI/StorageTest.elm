module WebAPI.StorageTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed, andThen)

import WebAPI.Storage exposing (..)


length0Test : Storage -> Task () Test
length0Test storage =
    clear storage `andThen`
    always (length storage) |>
        Task.map (assertEqual 0 >> test "length")


length1Test : Storage -> Task () Test
length1Test storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (length storage) |>
        Task.map (assertEqual 1 >> test "length") |>
            Task.mapError (always ())


keyTestSuccess : Storage -> Task () Test
keyTestSuccess storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (key storage 0) |>
        Task.map (assertEqual (Just "bob") >> test "keySuccess") |>
            Task.mapError (always ())


keyTestError : Storage -> Task () Test
keyTestError storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (key storage 5) |>
        Task.map (assertEqual Nothing >> test "keyError") |>
            Task.mapError (always ())


getItemTestSuccess : Storage -> Task () Test
getItemTestSuccess storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (get storage "bob") |>
        Task.map (assertEqual (Just "joe") >> test "getItemSuccess") |>
            Task.mapError (always ())


getItemTestError : Storage -> Task () Test
getItemTestError storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (get storage "wrong") |>
        Task.map (assertEqual Nothing >> test "getItemError") |>
            Task.mapError (always ())


removeItemTest : Storage -> Task () Test
removeItemTest storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (remove storage "bob") `andThen`
    always (length storage) |>
        Task.map (assertEqual 0 >> test "removeItem") |>
            Task.mapError (always ())


removeItemTestError : Storage -> Task () Test
removeItemTestError storage =
    clear storage `andThen`
    always (set storage "bob" "joe") `andThen`
    always (remove storage "not there") `andThen`
    always (length storage) |>
        Task.map (assertEqual 1 >> test "removeItem") |>
            Task.mapError (always ())


tests : Task () Test
tests =
    Task.map (suite "Storage") <|
        sequence <|
            List.map makeSuite
                [ (local, "localStorage")
                , (session, "sessionStorage")
                ]


makeSuite : (Storage, String) -> Task () Test
makeSuite (storage, label) =
    Task.map (suite label) <|
        sequence
            [ length0Test storage
            , length1Test storage
            , keyTestSuccess storage
            , keyTestError storage
            , getItemTestSuccess storage
            , getItemTestError storage
            , removeItemTest storage
            , removeItemTestError storage
            ]
