module CSV(graphFromCSV, csvFromGraph, xinput) where

-- sttp://web.engr.oregonstate.edu/~erwig/fgl/haskell/
{-| Build a SimpleGraph from a CSV file, export a SimpleGraph to a CSV file -}

import Text.ParserCombinators.Parsec
import qualified Data.Map.Strict as Map
import Data.Maybe(catMaybes)
import Data.Graph.Inductive.Graph (labEdges)
import Data.List (intercalate)
import SimpleGraph(SGNode, SGEdge, SimpleGraph
  , makeNode, makeEdge, makeGraph, nodeMap
  , sourceNode, targetNode, flowOnEdge)


data NNEdge = NNEdge { from :: String, to:: String, flow:: Float} deriving(Show )


csvFromGraph :: SimpleGraph -> String
csvFromGraph graph =
  let
    dict = nodeMap graph
    nnEdges = catMaybes (map (nnEdgeFromSGEdge dict) (labEdges graph))
  in
    intercalate "" (map stringOfNNEdge (reverse nnEdges))

stringOfNNEdge :: NNEdge -> String
stringOfNNEdge nnEdge =
  (from nnEdge) ++ "," ++ (to nnEdge) ++ "," ++ (show (flow nnEdge)) ++ "\n"

nnEdgeFromSGEdge :: Map.Map  Int String -> SGEdge -> Maybe NNEdge
nnEdgeFromSGEdge dict sgEdge =
  let
    maybeSourceLabel = Map.lookup (sourceNode sgEdge) dict
    maybeTargetLabel = Map.lookup (targetNode sgEdge) dict
  in
    case (maybeSourceLabel,  maybeTargetLabel) of
      (Just sourceLabel, Just targetLabel) ->  Just (NNEdge sourceLabel targetLabel (flowOnEdge sgEdge))
      (_, _) -> Nothing


foo graph =
  labEdges graph
-- indexMapFromNodeList :: [SGNode] -> Map String Int
-- indexMapFromNodeList

graphFromCSV :: String -> SimpleGraph
graphFromCSV input =
  let
    edgeList = nnEdgeListFromString input
    dict = (makeIndexMap . nodeNamesFromNNEdgeList) edgeList
    nodes = (makeNodeListFromIndex . makeIndex . nodeNamesFromNNEdgeList) edgeList
    edges = sgEdges dict edgeList
  in
    makeGraph nodes edges

sgEdges :: Map.Map String Int -> [NNEdge] -> [SGEdge]
sgEdges dict nnEdgeList =
  catMaybes (map (sgEdgeFromNNEdge dict) nnEdgeList)

sgEdgeFromNNEdge :: Map.Map String Int -> NNEdge -> Maybe SGEdge
sgEdgeFromNNEdge dict nnEdge =
  let
    iFrom = Map.lookup (from nnEdge) dict
    iTo = Map.lookup (to nnEdge) dict
  in
    case (iFrom, iTo) of
      (Just i, Just j) ->  Just (makeEdge i j (flow nnEdge))
      (_, _) -> Nothing

{-|
el = nnEdgeListFromString xinput
dd = (makeIndexMap . nodeNamesFromNNEdgeList) el
-}
makeIndexMap :: [String] -> Map.Map String Int
makeIndexMap list =
  Map.fromList (zip list [1..(length list)])

{-|
  *ghci > ii = makeIndex ["d","b","c","a"]
  *ghci > makeNodeListFromIndex ii
  [(1,NodeLabel {name = "d"}),(2,NodeLabel {name = "b"}),(3,NodeLabel {name = "c"}),(4,NodeLabel {name = "a"})]
-}
makeNodeListFromIndex :: [(String, Int)] -> [SGNode]
makeNodeListFromIndex index =
  map (\(n, i) -> makeNode i n) index
{-|
  *ghci > makeIndex ["d","b","c","a"]
  [("d",1),("b",2),("c",3),("a",4)]
-}
makeIndex :: [String] -> [(String, Int)]
makeIndex list =
  zip list [1..(length list)]


{-|
*ghci > xinput =  "a,b,1.2\nc,d,4.6\nc,e,8,9\n"
*ghci > el = nnEdgeListFromString xinput

-}
nnEdgeListFromString :: String -> [NNEdge]
nnEdgeListFromString input =
  case parseCSV input of
    Left _ -> []
    Right list -> map nnEdgeFromList list


{-|
  *ghci > xinput =  "a,b,1.2\nc,d,4.6\nc,e,8,9\n"
  *ghci > el = nnEdgeListFromString xinput
  *ghci > nodeNamesFromNNEdgeList el
  ["d","b","c","a"]
-}
nodeNamesFromNNEdgeList :: [NNEdge] -> [String]
nodeNamesFromNNEdgeList nnEdgeList =
  unique ((map from nnEdgeList) ++ (map to nnEdgeList))

unique :: Eq a => [a] -> [a]
unique = foldl (\acc x -> if (elem x acc) then acc else x:acc) []

{-|
*ghci > nnEdgeFromList ["a", "b", "1.22"]
NNEdge {from = "a", to = "b", flow = 1.22}
-}
nnEdgeFromList :: [String] ->  NNEdge
nnEdgeFromList list =
    let
      from = (list !! 0)
      to = (list !! 1)
      flow = read (list !! 2) :: Float
    in
      NNEdge from to flow

csvFile = endBy line eol
line = sepBy cell (char ',')
cell = many (noneOf ",\n")
eol = char '\n'

{-|
*ghci > parseCSV "a,b,1\nc,d,2\n"
Right [["a","b","1"],["c","d","2"]]
-}
parseCSV :: String -> Either ParseError [[String]]
parseCSV input = parse csvFile "(unknown)" input

xinput =  "a,b,1.2\nc,d,4.6\n"
