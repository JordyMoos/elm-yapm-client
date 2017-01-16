module NewMasterKey.Model exposing (Model, Fields, initModel)

import Dict exposing (Dict)


type alias Model =
  { fields : Fields
  }

type alias Fields = Dict String String


initModel : Model
initModel =
  { fields = initFields
  }


initFields : Fields
initFields =
  Dict.fromList
    [ ( "key", "" )
    , ( "repeat", "" )
    ]
