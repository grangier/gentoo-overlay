<?php 
require ( "sphinxapi.php" );
$sphinx = json_decode($_SERVER["argv"][1],true);
//print_r($sphinx);
$q = $sphinx['query'];
$mode = $sphinx['mode'];
$host = $sphinx['host'];
$port = $sphinx['port'];
$index = $sphinx['index'];
$anchor = $sphinx['anchor'];
#$groupby = "";
#$groupsort = "@group desc";
// $filter = $sphinx['filters'][0]['attr'];
// $filtervals = $sphinx['filters'][0]['values'];
// $exclude = $sphinx['filters'][0]['exclude'];

$filtersrange = $sphinx['filtersrange'][0];

$distinct = "";
$sortby = $sphinx['sortby'];
$sort = $sphinx['sort'];
$offset = intval($sphinx['offset']);
$limit = intval($sphinx['limit']);
$output = array();
//
$cl = new SphinxClient();
$cl->SetServer($host, $port);
$cl->SetWeights (array(100,1));
$cl->SetMatchMode($mode);
// sort by
if ( $sortby ) {
	$cl->SetSortMode ( $sort, $sortby );
} 
// geodist
if($anchor['lat'] && $anchor['long']) {
	// echo "DEGTORAD   " . deg2rad($anchor['lat']) ."\n";
	// echo "DEGTORAD   " . deg2rad($anchor['long']) ."\n";
	// echo "XXX   " . $anchor['attrlong'] ."\n";
	// echo "XXX   " . $anchor['attrlat'] ."\n";   
	$cl->SetGeoAnchor( $anchor['attrlat'], $anchor['attrlong'], deg2rad( $anchor['lat'] ), deg2rad( $anchor['long'] ) );
	$cl->SetMatchMode(SPH_SORT_EXTENDED);
	$cl->SetSortMode(SPH_SORT_EXTENDED, '@geodist asc');
	$cl->SetFilterFloatRange('@geodist',$sphinx['filtersrange'][0]['min'],$sphinx['filtersrange'][0]['max']);    
} elseif($filtersrange) {
	$cl->SetFilterRange($sphinx['filtersrange'][0]['attr'],$sphinx['filtersrange'][0]['min'],$sphinx['filtersrange'][0]['max']);
}
// limits
$cl->SetLimits ($offset,$limit,100000);
// filters
// if ( count($filtervals) )  { 
// 	echo "FILTER :" . $filter . "\n";
// 	echo "VALUE :" . $filtervals . "\n";
// 	$cl->SetFilter ( $filter, $filtervals, $exclude );     
// }

foreach($sphinx['filters'] as $fil) {
	$filter = $fil['attr'];
	$filtervals = $fil['values'];
	$exclude = $fil['exclude'];
	$cl->SetFilter ( $filter, $filtervals, $exclude );	
}
  
//if ( $groupby )				$cl->SetGroupBy ( $groupby, SPH_GROUPBY_ATTR, $groupsort );
//if ( $distinct )			$cl->SetGroupDistinct ( $distinct );
$res = $cl->Query ( $q, $index );
// ERRORS
if ( $res===false ) {
	$output['cmd']  = $sphinx;
	$output['error'] = $cl->GetLastError();
	$output['total_found'] = 0;
	$output['total'] = 0;
	$output['matches'] = array();
} else {
	//print_r($res);
	// WARNING
	if ( $cl->GetLastWarning() ) {
		$output['warning'] = $cl->GetLastWarning();
	}
	$output['total'] = intval($res['total']);
	$output['total_found'] = intval($res['total_found']);
	$output['time'] = intval($res['time']);
	$output['words'] = $res['words'];
	// WORDS
	if ( is_array($res["words"]) ) {
		$output['words'] = $res['words'];
	}
    // RESULTS ID
	if ( is_array($res["matches"]) ) {
		$output['matches'] = array();
		$n = 1;
		foreach ( $res["matches"] as $doc => $docinfo ) {
			//array_push ($output['matches'], $doc);
			$match = array();
			$match['id'] = $doc;
			$match['weight'] = $docinfo['weight'];
			$match['attrs'] = array();
			foreach ( $res["attrs"] as $attrname => $attrtype ) {
				// 
				$value = $docinfo["attrs"][$attrname];
				//echo  $attrname . '\n';
				if($attrname == '@geodist') {
					$attrname =  'geodist';
				} 
				//
				if ( $attrtype==SPH_ATTR_TIMESTAMP ) {
					$value = date ( "Y-m-d H:i:s", $value );
				}
					
				$match['attrs'][$attrname] = $value;
			}
			array_push ($output['matches'], $match); 
			$n++;
		}
	} else {
		$output['matches'] = array();
	}
} 
echo json_encode($output);
exit;
?>
