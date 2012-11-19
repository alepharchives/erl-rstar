-module(rstar_geometry).
-export([new/3, point2d/3, point3d/4, bounding_box/1]).

-include("../include/rstar.hrl").

% Creates a new geometry record
-spec new(integer(), list({float(), float()}), any()) -> {error, badarg} | #geometry{}.
new(Dimensions, _, _) when Dimensions < 1 -> {error, badarg};
new(Dimensions, MBR, Value) ->
    case valid_axes(MBR, 0) of
        {ok, Dimensions} ->
            #geometry{dimensions=Dimensions, mbr=MBR, value=Value};
        _ -> {error, badarg}
    end.


% Helper to create a 2D point
-spec point2d(float(), float(), any()) -> #geometry{}.
point2d(X, Y, Value) -> new(2, [{X, X}, {Y, Y}], Value).


% Helper to create a 3D point
-spec point3d(float(), float(), float(), any()) -> #geometry{}.
point3d(X, Y, Z, Value) -> new(3, [{X, X}, {Y, Y}, {Z, Z}], Value).


% Returns a new geometry which is a bounding box of
% the given geometries
-spec bounding_box([#geometry{}]) -> #geometry{}.
bounding_box([]) -> {error, badarg};
bounding_box([First | MoreGeo]) ->
    % Fold over each geometry and extend the MBR
    BindingMBR = lists:foldl(fun (Geo, Bounding) ->
        % Zip the MBR axes of the current Geometry with
        % that of the Bounding axes
        lists:zipwith(fun ({MinA, MaxA}, {MinB, MaxB}) ->
            {min(MinA, MinB), max(MaxA, MaxB)}
        end, Geo#geometry.mbr, Bounding)
    end, First#geometry.mbr, MoreGeo),

    % Create a binding geometry with the new MBR
    % and an undefined value
    First#geometry{mbr=BindingMBR, value=undefined}.


% Verifies that the max axis value is greater or equal to the minimum
valid_axes([], Length) -> {ok, Length};
valid_axes([{MinV, MaxV}| Other], Length) ->
    if
        MaxV >= MinV -> valid_axes(Other, Length + 1);
        true -> {error, {badarg, {MinV, MaxV}}}
    end.


