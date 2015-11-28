module Main where
import Html exposing (Html, Attribute, text, toElement, div, input)
import Html.Attributes exposing (..)
import Html.Events exposing (on, targetValue)
import Signal exposing (Address)
import StartApp.Simple as StartApp
import String
import Result exposing (Result)
import Array exposing (Array, get, set)


type Op = NiladicOp | MonadicOp | DyadicOp | VariadicOp
type NiladicOp = ErrorOp
type MonadicOp = Minus
type DyadicOp = Sub | Pow
type VariadicOp = Add | Mult

type alias GridId = Int -- because using Array.set and Array.get

type Atom = Number Float | Text String | Error
type AST a = Node Op (List (AST a)) | Leaf a

type CellContent = Value Atom | Reference GridId | Formula (AST CellContent)
type alias Cell =
            { dependentCells: List GridId
            , underlying: CellContent
            , currentValue : Atom
            }
type alias Grid =
            { width : Int
            , height : Int
            , data  : Array Cell
            }

cellsReferenced: CellContent -> List GridId
cellsReferenced cell =
  let refs x c = case c of
    Value atom
      -> x
    Reference ref
      -> ref::x

    Formula (Leaf c')
      -> refs x c'
    Formula (Node op cs)
      -> x ++ List.concat (List.map (\c-> refs [] (Formula c)) cs )
  in refs [] cell

parse: String -> Result String CellContent
parse s = Ok (Value (Number 42))

updateData : Array Cell -> GridId -> CellContent -> Result String (Array Cell)
updateData data ix newContent =
  case get ix data of
    Nothing
      -> Err "Failed lookup"
    Just cell
      -> let
          data1 = set ix {cell | underlying = newContent, currentValue = Error } data
          data2 = addDependenciesFromNewCell data1 newContent
          indicesToRecompute = case bfs data2 [] [ix] of
            Err (Message str)
              -> Err str
            Err (CircularDependencyDetected)
              -> Err "Circular dependency TODO handle"
            Ok indices -> Ok indices
        in
          Result.map (recompute data2) indicesToRecompute

{-
Recomputes current values based on supplied safe order.
-}
recompute: Array Cell -> List GridId -> Array Cell
recompute data changed = data

addDependenciesFromNewCell: Array Cell -> CellContent -> Array Cell
addDependenciesFromNewCell data cellContent =
    let
      updateCell data1 ref = case get ref data of
          Nothing
            -> data1
          Just cell
            -> set ref {cell | dependentCells = ref:: cell.dependentCells } data1
      updateCells data1 refs = case refs of
        []
          -> data1
        r::rs
          ->
        updateCells (updateCell data1 r) rs
    in
      updateCells data (cellsReferenced cellContent)

type BfsFailure = Message String | CircularDependencyDetected

bfs: Array Cell -> List (GridId, List GridId) -> List GridId -> Result BfsFailure (List GridId)
bfs data blacks greys =Err (Message "Implement me")

  {-case greys of
  []
    -> Just blacks
  x::xs
    ->  get x data
        |> map .dependentCells
        |> map

-}



{-

update : Grid -> Int -> Int ->String-> Result String Grid
update grid x y newContent =
  let
  parseResult = parse newContent
  cellResult  = if (x<1 or x>grid.width or y<1 or y>grid.height)
                  Err "Wrong dimensions"
                else
                  Ok (y-1)*grid.width + x
                  `andThen`
                  \ix -> get ix grid.data
                  `andThen`
                  \ar -> case ar of
                    Nothing
                      -> Err "Failed array lookup, should not happen"
                    Just cell
                      -> Ok cell
  in
    map2 (updateCellIn grid) parseResult cellResult

getCell: Grid -> GridId -> Maybe Cell
getCell grid ix

updateCellIn: Grid -> CellContent -> Cell -> Grid
--}



main =
  StartApp.start { model = "", view = view, update = update }


update newStr oldStr =
  newStr


view : Address String -> String -> Html
view address string =
  div []
    [ input
        [ placeholder "Text to reverse"
        , value string
        , on "input" targetValue (Signal.message address)
        , myStyle
        ]
        []
    , div [ myStyle ] [ text (String.reverse string) ]
    ]


myStyle : Attribute
myStyle =
  style
    [ ("width", "100%")
    , ("height", "40px")
    , ("padding", "10px 0")
    , ("font-size", "2em")
    , ("text-align", "center")
    ]