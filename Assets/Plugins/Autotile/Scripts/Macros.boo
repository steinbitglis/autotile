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

macro all_corners(corners as Boo.Lang.Compiler.Ast.ReferenceExpression, f as Boo.Lang.Compiler.Ast.ReferenceExpression):
    yield [|
        $f($corners.aaaa, "AAAA")
        $f($corners.aaad, "AAAD")
        $f($corners.aada, "AADA")
        $f($corners.aadd, "AADD")
        $f($corners.aarg, "AARG")
        $f($corners.adaa, "ADAA")
        $f($corners.adad, "ADAD")
        $f($corners.adda, "ADDA")
        $f($corners.addd, "ADDD")
        $f($corners.adrg, "ADRG")
        $f($corners.agbg, "AGBG")
        $f($corners.agla, "AGLA")
        $f($corners.agld, "AGLD")
        $f($corners.bbbb, "BBBB")
        $f($corners.bblc, "BBLC")
        $f($corners.bcac, "BCAC")
        $f($corners.bcdc, "BCDC")
        $f($corners.bcrb, "BCRB")
        $f($corners.daaa, "DAAA")
        $f($corners.daad, "DAAD")
        $f($corners.dada, "DADA")
        $f($corners.dadd, "DADD")
        $f($corners.darg, "DARG")
        $f($corners.ddaa, "DDAA")
        $f($corners.ddad, "DDAD")
        $f($corners.ddda, "DDDA")
        $f($corners.dddd, "DDDD")
        $f($corners.ddrg, "DDRG")
        $f($corners.dgbg, "DGBG")
        $f($corners.dgla, "DGLA")
        $f($corners.dgld, "DGLD")
        $f($corners.lbbg, "LBBG")
        $f($corners.lbla, "LBLA")
        $f($corners.lbld, "LBLD")
        $f($corners.lcaa, "LCAA")
        $f($corners.lcad, "LCAD")
        $f($corners.lcda, "LCDA")
        $f($corners.lcdd, "LCDD")
        $f($corners.lcrg, "LCRG")
        $f($corners.raac, "RAAC")
        $f($corners.radc, "RADC")
        $f($corners.rarb, "RARB")
        $f($corners.rdac, "RDAC")
        $f($corners.rddc, "RDDC")
        $f($corners.rdrb, "RDRB")
        $f($corners.rgbb, "RGBB")
        $f($corners.rglc, "RGLC")
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

macro hface_directions_cgx (faceDirection as ReferenceExpression):
    yield [|
        if $faceDirection == HorizontalFace.Down:
            $(hface_directions_cgx.Body.Statements[0])
        elif $faceDirection == HorizontalFace.Up:
            $(hface_directions_cgx.Body.Statements[1])
        else:
            $(hface_directions_cgx.Body.Statements[2])
    |]

macro vface_directions_lrx (faceDirection as ReferenceExpression):
    yield [|
        if $faceDirection == VerticalFace.Left:
            $(vface_directions_lrx.Body.Statements[0])
        elif $faceDirection == VerticalFace.Right:
            $(vface_directions_lrx.Body.Statements[1])
        else:
            $(vface_directions_lrx.Body.Statements[2])
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
