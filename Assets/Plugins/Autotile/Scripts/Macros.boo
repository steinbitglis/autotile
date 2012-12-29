import Boo.Lang.Compiler.Ast

macro inline_enum (enumName as ReferenceExpression):
    ### Example of 'inline_enum' ###
    # inline_enum direction:
    #     left
    #     right

    # =>

    # static private final numDirections = 2
    # static private final left = 0
    # static private final right = 1

    numEnums = ReferenceExpression("num" + enumName.Name[0:1].ToUpper() + enumName.Name[1:] + "s")
    yield [|
        static public final $numEnums = $(len(inline_enum.Body.Statements))
    |]
    for i as long, statement in enumerate(inline_enum.Body.Statements):
        es = statement as ExpressionStatement
        # expressions will end with '()', or they would be unfit
        name = ReferenceExpression(es.Expression.ToString()[:-2])
        yield [|
            static public final $name = $i
        |]

macro all_corners(tileset as ReferenceExpression, corners as ReferenceExpression, f as ReferenceExpression):
    yield [|
        $f($tileset, $corners.aaaa, "AAAA")
        $f($tileset, $corners.aaad, "AAAD")
        $f($tileset, $corners.aada, "AADA")
        $f($tileset, $corners.aadd, "AADD")
        $f($tileset, $corners.aarg, "AARG")
        $f($tileset, $corners.adaa, "ADAA")
        $f($tileset, $corners.adad, "ADAD")
        $f($tileset, $corners.adda, "ADDA")
        $f($tileset, $corners.addd, "ADDD")
        $f($tileset, $corners.adrg, "ADRG")
        $f($tileset, $corners.agbg, "AGBG")
        $f($tileset, $corners.agla, "AGLA")
        $f($tileset, $corners.agld, "AGLD")
        $f($tileset, $corners.bbbb, "BBBB")
        $f($tileset, $corners.bblc, "BBLC")
        $f($tileset, $corners.bcac, "BCAC")
        $f($tileset, $corners.bcdc, "BCDC")
        $f($tileset, $corners.bcrb, "BCRB")
        $f($tileset, $corners.daaa, "DAAA")
        $f($tileset, $corners.daad, "DAAD")
        $f($tileset, $corners.dada, "DADA")
        $f($tileset, $corners.dadd, "DADD")
        $f($tileset, $corners.darg, "DARG")
        $f($tileset, $corners.ddaa, "DDAA")
        $f($tileset, $corners.ddad, "DDAD")
        $f($tileset, $corners.ddda, "DDDA")
        $f($tileset, $corners.dddd, "DDDD")
        $f($tileset, $corners.ddrg, "DDRG")
        $f($tileset, $corners.dgbg, "DGBG")
        $f($tileset, $corners.dgla, "DGLA")
        $f($tileset, $corners.dgld, "DGLD")
        $f($tileset, $corners.lbbg, "LBBG")
        $f($tileset, $corners.lbla, "LBLA")
        $f($tileset, $corners.lbld, "LBLD")
        $f($tileset, $corners.lcaa, "LCAA")
        $f($tileset, $corners.lcad, "LCAD")
        $f($tileset, $corners.lcda, "LCDA")
        $f($tileset, $corners.lcdd, "LCDD")
        $f($tileset, $corners.lcrg, "LCRG")
        $f($tileset, $corners.raac, "RAAC")
        $f($tileset, $corners.radc, "RADC")
        $f($tileset, $corners.rarb, "RARB")
        $f($tileset, $corners.rdac, "RDAC")
        $f($tileset, $corners.rddc, "RDDC")
        $f($tileset, $corners.rdrb, "RDRB")
        $f($tileset, $corners.rgbb, "RGBB")
        $f($tileset, $corners.rglc, "RGLC")
        $f($tileset, $corners.unknown, "Unknown")
    |]

macro binary_search_autotile_connection(index as Expression):
    assert index isa ReferenceExpression or index isa IntegerLiteralExpression
    yield [|
        if $index < 8:
            if $index < 4:
                if $index < 2:
                    if $index < 1:
                        $(binary_search_autotile_connection.Body.Statements[0])
                    else:
                        $(binary_search_autotile_connection.Body.Statements[1])
                else:
                    if $index < 3:
                        $(binary_search_autotile_connection.Body.Statements[2])
                    else:
                        $(binary_search_autotile_connection.Body.Statements[3])
            else:
                if $index < 6:
                    if $index < 5:
                        $(binary_search_autotile_connection.Body.Statements[4])
                    else:
                        $(binary_search_autotile_connection.Body.Statements[5])
                else:
                    if $index < 7:
                        $(binary_search_autotile_connection.Body.Statements[6])
                    else:
                        $(binary_search_autotile_connection.Body.Statements[7])
        else:
            if $index < 12:
                if $index < 10:
                    if $index < 9:
                        $(binary_search_autotile_connection.Body.Statements[8])
                    else:
                        $(binary_search_autotile_connection.Body.Statements[9])
                else:
                    if $index < 11:
                        $(binary_search_autotile_connection.Body.Statements[10])
                    else:
                        $(binary_search_autotile_connection.Body.Statements[11])
    |]

macro hface_directions_cgxn (faceDirection as ReferenceExpression):
    yield [|
        if $faceDirection == HorizontalFace.Down:
            $(hface_directions_cgxn.Body.Statements[0])
        elif $faceDirection == HorizontalFace.Up:
            $(hface_directions_cgxn.Body.Statements[1])
        elif $faceDirection == HorizontalFace.Double:
            $(hface_directions_cgxn.Body.Statements[2])
        else:
            $(hface_directions_cgxn.Body.Statements[3])
    |]

macro vface_directions_lrxn (faceDirection as ReferenceExpression):
    yield [|
        if $faceDirection == VerticalFace.Left:
            $(vface_directions_lrxn.Body.Statements[0])
        elif $faceDirection == VerticalFace.Right:
            $(vface_directions_lrxn.Body.Statements[1])
        elif $faceDirection == VerticalFace.Double:
            $(vface_directions_lrxn.Body.Statements[2])
        else:
            $(vface_directions_lrxn.Body.Statements[3])
    |]

macro if_00_01_10_11 (msb as ReferenceExpression, lsb as ReferenceExpression):
    yield [|
        if not $msb:
            if not $lsb:
                $(if_00_01_10_11.Body.Statements[0])
            else:
                $(if_00_01_10_11.Body.Statements[1])
        else:
            if not $lsb:
                $(if_00_01_10_11.Body.Statements[2])
            else:
                $(if_00_01_10_11.Body.Statements[3])
    |]
