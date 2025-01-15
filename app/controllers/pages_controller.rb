class PagesController < ApplicationController
  require "httparty"
  require "csv"

  def search
    site = params[:site] # e.g., 'bindlez.myshopify.com'
    product_name = params[:product_name] # e.g., 'smok'
    source = params[:source] # 'api' or 'csv'

    if source == "api"
      # Fetch products from the provided site's API
      begin
        url = "https://#{site}/products/#{product_name}.json"
        p url
        response = HTTParty.get(url)
        p response

        if response.success?
          # Parse the JSON response and filter products by name
          products = JSON.parse(response.body)["products"]
          filtered_products = products.select { |product| product["title"].downcase.include?(product_name.downcase) }

          render json: { status: "success", products: filtered_products }
        else
          render json: { status: "error", message: "Failed to fetch products from the API." }, status: :bad_request
        end
      rescue StandardError => e
        render json: { status: "error", message: e.message }, status: :internal_server_error
      end
    elsif source == "csv"
      # Handle CSV file upload and filter products by name
      if params[:file].present? && params[:file].content_type == "text/csv"
        begin
          products = []
          CSV.foreach(params[:file].path, headers: true) do |row|
            products << row.to_hash
          end

          # Filter products by name
          filtered_products = products.select { |product| product["title"].downcase.include?(product_name.downcase) }

          render json: { status: "success", products: filtered_products }
        rescue StandardError => e
          render json: { status: "error", message: e.message }, status: :internal_server_error
        end
      else
        render json: { status: "error", message: "Invalid or missing CSV file." }, status: :bad_request
      end
    else
      render json: { status: "error", message: "Invalid source. Use 'api' or 'csv'." }, status: :unprocessable_entity
    end
  end
end
