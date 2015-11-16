module WebAPI.LocationTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed, andThen)
import String

import WebAPI.Location exposing (..)


locationTest : Task () Test
locationTest =
    location |>
        Task.map (\loc ->
            suite "location"
                [ test "hash" <| assertEqual "" loc.hash
                , test "host" <| assertEqual "localhost:8080" loc.host
                , test "hostname" <| assertEqual "localhost" loc.hostname
                , test "href" <|
                    assert <|
                        List.all identity
                            [ String.startsWith "http://" loc.href
                            , String.endsWith "elm.html" loc.href
                            ]
                , test "origin" <| assertEqual "http://localhost:8080" loc.origin
                , test "pathname" <|
                    assert <|
                        List.all identity
                            [ String.startsWith "/" loc.pathname
                            , String.endsWith "elm.html" loc.pathname
                            ]
                , test "port'" <| assertEqual "8080" loc.port'
                , test "protocol" <| assertEqual "http:" loc.protocol
                , test "search" <| assertEqual "" loc.search
                ]
        )


tests : Task () Test
tests =
    Task.map (suite "WebAPI.LocationTest") <|
        sequence <|
            [ locationTest
            ]

