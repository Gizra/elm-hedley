module WebAPI.DateTest where

import ElmTest.Test exposing (..)
import ElmTest.Assertion exposing (..)
import Task exposing (Task, sequence, succeed, andThen)

import WebAPI.Date exposing (..)
import Date
import Time
import String


testCurrent : Task x Test
testCurrent =
    current |>
        Task.map (\c ->
            test "current" <|
                assert <|
                    (Date.year c) > 2014
        )


testNow : Task x Test
testNow =
    now |>
        Task.map (\n ->
            test "now" <|
                assert <|
                    n > 1445463720748
        )


testTimezoneOffset : Test
testTimezoneOffset =
    let
        date =
            fromParts Local (Parts 2015 1 1 1 1 1 1)

    in
        test "timezoneOffset" <|
            assert <|
                (abs (timezoneOffset date)) < (12 * Time.hour)


testFromPartsLocal : Test
testFromPartsLocal =
    let
        date =
            fromParts Local (Parts 2015 1 2 3 4 5 6)

        tuple =
            ( Date.year date
            , Date.month date
            , Date.day date
            , Date.hour date
            , Date.minute date
            , Date.second date
            , Date.millisecond date
            )

    in
        test "fromParts Local" <|
            assertEqual
                (2015, Date.Feb, 2, 3, 4, 5, 6)
                tuple


testFromAndToParts : String -> Timezone -> Test
testFromAndToParts title zone =
    let
        parts =
            Parts 2015 1 2 3 4 5 6
        
        date =
            fromParts zone parts

        result =
            toParts zone date

        back =
            fromParts zone result

    in
        test title <|
            assertEqual
                (Date.toTime date)
                (Date.toTime back)


testDayOfWeek : String -> Timezone -> Test
testDayOfWeek title zone =
    let
        makeTest (string, expected, parts) =
            test string <|
                assertEqual expected <|
                    dayOfWeek zone (fromParts zone parts)

    in
        suite title <|
            List.map makeTest
                [ ("Sunday", Date.Sun, Parts 2015 1 1 0 0 0 0)
                , ("Monday", Date.Mon, Parts 2015 1 2 0 0 0 0)
                , ("Tuesday", Date.Tue, Parts 2015 1 3 0 0 0 0)
                , ("Wednesday", Date.Wed, Parts 2015 1 4 0 0 0 0)
                , ("Thursday", Date.Thu, Parts 2015 1 5 0 0 0 0)
                , ("Friday", Date.Fri, Parts 2015 1 6 0 0 0 0)
                , ("Saturday", Date.Sat, Parts 2015 1 7 0 0 0 0)
                ] 


testToMonth : Test
testToMonth =
    let
        makeTest (input, expected) =
            test (toString input) <|
                assertEqual
                    expected
                    (toMonth input)
    
    in
        suite "toMonth" <|
            List.map makeTest
                [ (-8, Date.May)
                , (-7, Date.Jun)
                , (-6, Date.Jul)
                , (-5, Date.Aug)
                , (-4, Date.Sep)
                , (-3, Date.Oct)
                , (-2, Date.Nov)
                , (-1, Date.Dec)
                , (0, Date.Jan)
                , (1, Date.Feb)
                , (2, Date.Mar)
                , (3, Date.Apr)
                , (4, Date.May)
                , (5, Date.Jun)
                , (6, Date.Jul)
                , (7, Date.Aug)
                , (8, Date.Sep)
                , (9, Date.Oct)
                , (10, Date.Nov)
                , (11, Date.Dec)
                , (12, Date.Jan)
                , (13, Date.Feb)
                ]


testFromMonth : Test
testFromMonth =
    let
        makeTest (expected, input) =
            test (toString input) <|
                assertEqual
                    expected
                    (fromMonth input)
    
    in
        suite "fromMonth" <|
            List.map makeTest
                [ (0, Date.Jan)
                , (1, Date.Feb)
                , (2, Date.Mar)
                , (3, Date.Apr)
                , (4, Date.May)
                , (5, Date.Jun)
                , (6, Date.Jul)
                , (7, Date.Aug)
                , (8, Date.Sep)
                , (9, Date.Oct)
                , (10, Date.Nov)
                , (11, Date.Dec)
                ]


testToDay : Test
testToDay =
    let
        makeTest (input, expected) =
            test (toString input) <|
                assertEqual
                    expected
                    (toDay input)
    
    in
        suite "toMonth" <|
            List.map makeTest
                [ (-8, Date.Sat)
                , (-7, Date.Sun)
                , (-6, Date.Mon)
                , (-5, Date.Tue)
                , (-4, Date.Wed)
                , (-3, Date.Thu)
                , (-2, Date.Fri)
                , (-1, Date.Sat)
                , (0, Date.Sun)
                , (1, Date.Mon)
                , (2, Date.Tue)
                , (3, Date.Wed)
                , (4, Date.Thu)
                , (5, Date.Fri)
                , (6, Date.Sat)
                , (7, Date.Sun)
                , (8, Date.Mon)
                , (9, Date.Tue)
                , (10, Date.Wed)
                , (11, Date.Thu)
                , (12, Date.Fri)
                , (13, Date.Sat)
                ]


testFromDay : Test
testFromDay =
    let
        makeTest (expected, input) =
            test (toString input) <|
                assertEqual
                    expected
                    (fromDay input)
    
    in
        suite "fromMonth" <|
            List.map makeTest
                [ (0, Date.Sun)
                , (1, Date.Mon)
                , (2, Date.Tue)
                , (3, Date.Wed)
                , (4, Date.Thu)
                , (5, Date.Fri)
                , (6, Date.Sat)
                ]


offsetTimeTest : Test
offsetTimeTest =
    let
        date =
            fromParts Local (Parts 2015 1 2 3 4 5 6)

        forward =
            fromParts Local (Parts 2015 1 2 3 5 5 6)

        backward =
            fromParts Local (Parts 2015 1 2 3 3 5 6)
        
        offsetTimePositive =
            test "positive" <|
                assertEqual
                    (Date.toTime forward)
                    (Date.toTime (offsetTime (1 * Time.minute) date))

        offsetTimeNegative =
            test "negative" <|
                assertEqual
                    (Date.toTime backward)
                    (Date.toTime (offsetTime (-1 * Time.minute) date))

    in
        suite "offsetTime"
            [ offsetTimePositive
            , offsetTimeNegative
            ]


offsetYearTest : String -> Timezone -> Test
offsetYearTest title zone =
    let
        date =
            fromParts zone (Parts 2015 1 2 3 4 5 6)

        forward =
            fromParts zone (Parts 2016 1 2 3 4 5 6)

        backward =
            fromParts zone (Parts 2014 1 2 3 4 5 6)
        
        offsetYearPositive =
            test "positive" <|
                assertEqual
                    (Date.toTime forward)
                    (Date.toTime (offsetYear zone 1 date))
        
        offsetYearNegative =
            test "negative" <|
                assertEqual
                    (Date.toTime backward)
                    (Date.toTime (offsetYear zone -1 date))

    in
        suite title
            [ offsetYearPositive
            , offsetYearNegative
            ]


offsetMonthTest : String -> Timezone -> Test
offsetMonthTest title zone =
    let
        date =
            fromParts zone (Parts 2015 0 2 3 4 5 6)

        forward =
            fromParts zone (Parts 2015 1 2 3 4 5 6)

        backward =
            fromParts zone (Parts 2014 11 2 3 4 5 6)
        
        offsetPositive =
            test "positive" <|
                assertEqual
                    (Date.toTime forward)
                    (Date.toTime (offsetMonth zone 1 date))
        
        offsetNegative =
            test "negative" <|
                assertEqual
                    (Date.toTime backward)
                    (Date.toTime (offsetMonth zone -1 date))

    in
        suite title
            [ offsetPositive
            , offsetNegative
            ]


timescale : Test
timescale =
    suite "timescale"
        [ test "day" <| assertEqual 86400000 day
        , test "inDays" <| assertEqual 1 (inDays 86400000)
        , test "week" <| assertEqual 604800000 week
        , test "inWeeks" <| assertEqual 1 (inWeeks 604800000)
        ]


strings : Test
strings =
    let
        date =
            fromParts UTC (Parts 2015 0 2 3 4 5 6)

        utc =
            utcString date

    in
        suite "Strings"
            -- For dateString and timeString, we'd have to do some calculation
            -- based on timezoneOffset to figure out the real expectation
            [ test "dateString" <| assert <| String.length (dateString date) > 6
            , test "timeString" <| assert <| String.length (timeString date) > 6
            , test "isoString" <| assertEqual "2015-01-02T03:04:05.006Z" (isoString date)
            , test ("utcString " ++ utc)  <| 
                assert <|
                    "Fri, 02 Jan 2015 03:04:05 GMT" == utc ||
                    -- This is from IE 10 
                    "Fri, 2 Jan 2015 03:04:05 UTC" == utc
            ]


tests : Task () Test
tests =
    Task.map (suite "WebAPI.DateTest") <|
        sequence <|
            [ testCurrent
            , testNow
            ]
            ++
            List.map Task.succeed
                [ testTimezoneOffset
                , testFromPartsLocal
                , testFromAndToParts "fromParts and toParts Local" Local
                , testFromAndToParts "fromParts and toParts UTC" UTC
                , testDayOfWeek "dayOfWeek Local" Local
                , testDayOfWeek "dayOfWeek UTC" UTC
                , testToMonth, testFromMonth
                , testToDay, testFromDay
                , offsetTimeTest
                , offsetYearTest "offsetYear Local" Local
                , offsetYearTest "offsetYear UTC" UTC
                , offsetMonthTest "offsetMonth Local" Local
                , offsetMonthTest "offsetMonth UTC" UTC
                , timescale
                , strings
                ]

