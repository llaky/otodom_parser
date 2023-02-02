<?php
/*
*  @author: Denis Romaniko
*/

define('ADMIN_COOKIE_PATH', '/');
define('COOKIEPATH', '/');
define('SITECOOKIEPATH', '/');
require_once($_SERVER['DOCUMENT_ROOT'] . '/home/USER/domains/DOMAIN/public_html/wp-load.php');

$directory_url=get_option('_iv_property_url');
if($directory_url==""){$directory_url='property';}
$main_class = new wp_iv_property;
$form_data = array('id', 'post_title', 'post_content', 'category', 'tag', 'featured-image', 'image_gallery_urls', 'property_status', 'bedrooms', 'bathrooms', 'guest', 'garages', 'sale_or_rent_price', 'price_postfix_text', 'area', 'area_postfix_text', 'address', 'local-area', 'latitude', 'longitude', 'city', 'postcode', 'state', 'country', 'phone', 'contact-email', 'contact_web', 'youtube-video', 'facebook', 'linkedin', 'vimeo', 'Property_ID', 'Available_From', 'Year_Built', 'Exterior_Material');

$csv = $argv[1];

$default_fields = array();
$default_fields['Property_ID']='Property ID';
$default_fields['Available_From']='Available From';
$default_fields['Year_Built']='Year Built';
$default_fields['Exterior_Material']='Exterior Material';
/*
$default_fields['Structure_Type']='Structure Type';
$default_fields['AC']='AC';
$default_fields['Acres']='Acres';
$default_fields['Bedroom_Features']='Bedroom Features';
$default_fields['Cross_Streets']='Cross Streets';
$default_fields['Dining_Area']='Dining Area';
$default_fields['Disability_Access']='Disability Access';
$default_fields['Entry_Location']='Entry Location';
$default_fields['Exterior_Cnstruction']='Exterior Cnstruction';
$default_fields['Fireplace_Fuel']='Fireplace Fuel';
$default_fields['Fireplace_Location']='Fireplace Location';
$default_fields['Legal_Desc']='Legal Desc';
$default_fields['Lot_Description']='Lot Description';
$default_fields['Lot_Size_Source']='Lot Size Source';
$default_fields['Misc_Interior']='Misc Interior';
$default_fields['Sewer']='Sewer';
$default_fields['Source_Of_Sqft']='Source Of Sqft';
$default_fields['Terms']='Terms';
$default_fields['View_Desc']='View Desc';
*/

if (($handle = fopen($csv, 'r' )) !== FALSE) {
	$top_header = fgetcsv($handle, 1000, ",");
	while (($data = fgetcsv($handle)) !== FALSE) {
		$i=0;
		$post_id=0;
		$post_data=array();

		foreach($data as $one_col){
			if(in_array("ID", $top_header) OR in_array("Id", $top_header) OR in_array("id", $top_header)){
				// Check ID 
				if(strtolower($top_header[$i])=='id'){
					if(trim($one_col)!=''){
						$post_check=get_post($one_col);
						if ( isset($post_check->post_type) and $post_check->post_type==$directory_url ) {
							$post_id=$one_col;
						}else{
							$post_id=0;
						}
					}
				}else{
					$top_header_i=str_replace (' ','-', $top_header[$i]);
					$post_data[$form_data[$i]]=$one_col;
				}
			}else{
				$top_header_i=str_replace (' ','-', $top_header[$i]);
				$post_data[$form_data[$i]]=$one_col;
				$post_id=0;
			}
			$i++;
		}

		if($post_id==0){
			// Insert Post
			$my_post=array();
			$my_post['post_title'] = sanitize_text_field($post_data['post_title']);
			$my_post['post_content'] = sanitize_text_field($post_data['post_content']);
			$my_post['post_author'] = 2;
			$my_post['post_date'] = date("Y-m-d H:i:s");
			$my_post['post_status'] = 'publish';
			$my_post['post_type'] = $directory_url;
			$post_id= wp_insert_post( $my_post );
		}else{
			$my_post=array();
			$my_post['ID'] = $post_id;
			$my_post['post_title'] = sanitize_text_field($post_data['post_title']);
			$my_post['post_content'] = sanitize_text_field($post_data['post_content']);
			$my_post['post_status'] = 'publish';
			$my_post['post_type'] = $directory_url;
			wp_update_post($my_post);
		}

		if(isset($post_data['category'])) {
			$post_cat_arr =explode(",",$post_data['category']);
			wp_set_object_terms( $post_id, $post_cat_arr, $directory_url.'-category');
		}
		if(isset($post_data['tag'])) {
			$post_tag_arr =explode(",",$post_data['tag']) ;
			wp_set_object_terms( $post_id, $post_tag_arr, $directory_url.'_tag');
		}
		if(isset($post_data['featured-image'])){
			if(strlen(trim($post_data['featured-image']))>3){
				$main_class->eppro_upload_featured_image($post_data['featured-image'], $post_id);
			}
		}
		if(isset($post_data['image_gallery_urls'])) {
			update_post_meta($post_id, 'image_gallery_urls', $post_data['image_gallery_urls']);
		}
		if(isset($post_data['property_status'])){
			update_post_meta($post_id, 'property_status', sanitize_text_field($post_data['property_status']));
		}
		if(isset($post_data['bedrooms'])){
			update_post_meta($post_id, 'bedrooms', sanitize_text_field($post_data['bedrooms']));
		}
		if(isset($post_data['bathrooms'])){
			update_post_meta($post_id, 'bathrooms', sanitize_text_field($post_data['bathrooms']));
		}
		if(isset($post_data['guest'])){
			update_post_meta($post_id, 'guest', sanitize_text_field($post_data['guest']));
		}
		if(isset($post_data['garages'])){
			update_post_meta($post_id, 'garages', sanitize_text_field($post_data['garages']));
		}
		if(isset($post_data['sale_or_rent_price'])){
			update_post_meta($post_id, 'sale_or_rent_price', sanitize_text_field($post_data['sale_or_rent_price']));
		}
		if(isset($post_data['price_postfix_text'])){
			update_post_meta($post_id, 'price_postfix_text', sanitize_text_field($post_data['price_postfix_text']));
		}
		if(isset($post_data['area'])){
			update_post_meta($post_id, 'area', sanitize_text_field($post_data['area']));
		}
		if(isset($post_data['address'])){
			update_post_meta($post_id, 'address', sanitize_text_field($post_data['address']));
		}
		if(isset($post_data['local-area'])){
			update_post_meta($post_id, 'local-area', sanitize_text_field($post_data['local-area']));
		}
		if(isset($post_data['area_postfix_text'])){
			update_post_meta($post_id, 'area_postfix_text', sanitize_text_field($post_data['area_postfix_text']));
		}
		if(isset($post_data['latitude'])){
			update_post_meta($post_id, 'latitude', sanitize_text_field($post_data['latitude']));
		}
		if(isset($post_data['longitude'])){
			update_post_meta($post_id, 'longitude', sanitize_text_field($post_data['longitude']));
		}
		if(isset($post_data['city'])){
			update_post_meta($post_id, 'city', sanitize_text_field($post_data['city']));
		}
		if(isset($post_data['postcode'])){
			update_post_meta($post_id, 'postcode', sanitize_text_field($post_data['postcode']));
		}
		if(isset($post_data['state'])){
			update_post_meta($post_id, 'state', sanitize_text_field($post_data['state']));
		}
		if(isset($post_data['country'])){
			update_post_meta($post_id, 'country', sanitize_text_field($post_data['country']));
		}
		if(isset($post_data['phone'])){
			update_post_meta($post_id, 'phone', sanitize_text_field($post_data['phone']));
		}
		if(isset($post_data['contact-email'])){
			update_post_meta($post_id, 'contact-email', sanitize_text_field($post_data['contact-email']));
		}
		if(isset($post_data['contact_web'])){
			update_post_meta($post_id, 'contact_web', sanitize_text_field($post_data['contact_web']));
		}
		if(isset($post_data['youtube-video'])){
			update_post_meta($post_id, 'youtube', sanitize_text_field($post_data['youtube-video']));
		}
		if(isset($post_data['facebook'])){
			update_post_meta($post_id, 'facebook', sanitize_text_field($post_data['facebook']));
		}
		if(isset($post_data['linkedin'])){
			update_post_meta($post_id, 'linkedin', sanitize_text_field($post_data['linkedin']));
		}
		if(isset($post_data['vimeo'])){
			update_post_meta($post_id, 'vimeo', sanitize_text_field($post_data['vimeo']));
		}

		if(sizeof($default_fields )){
			foreach( $default_fields as $field_key => $field_value ) {
				update_post_meta($post_id, $field_key, $post_data[$field_key] );
			}
		}
	}//while
}

fclose($handle);
?>
