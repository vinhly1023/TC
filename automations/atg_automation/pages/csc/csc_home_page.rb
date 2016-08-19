class CSCHomePage < SitePrism::Page
  element :order_search_string, :xpath, ".//*[@id='cmcOrderSearchPS_cmcOrderSearchP_2']//h3"
  element :order_summanry_string, :xpath, ".//*[@id='cmcHelpfulPanels_orderSummaryPanel_1']//h3"
end
