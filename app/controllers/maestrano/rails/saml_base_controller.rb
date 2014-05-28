class Maestrano::Rails::SamlBaseController < ApplicationController
  attr_reader :saml_response, :user_auth_hash, :group_auth_hash
  around_filter :saml_response_transaction, only: [:consume]
  
  # Initialize the SAML request and redirects the
  # user to Maestrano
  def init
    redirect_to Maestrano::Saml::Request.new(params,session).redirect_url
  end
  
  #===================================
  # Helper methods
  #===================================
  def saml_response_transaction
    begin
      process_saml_response
      yield
      set_maestrano_session
    rescue Exception => e
    end
  end
  
  def process_saml_response
    if params[:SAMLResponse]
      @saml_response = Maestrano::Saml::Response.new(params[:SAMLResponse])
      if @saml_response.is_valid?
        @user_auth_hash = Maestrano::SSO::BaseUser.new(@saml_response).to_hash
        @group_auth_hash = Maestrano::SSO::BaseGroup.new(@saml_response).to_hash
      end
    end
  end
  
  def set_maestrano_session
    if @user_auth_hash && session
      session[:mno_uid] = @saml_response.attributes['uid']
      session[:mno_session] = @saml_response.attributes['mno_session']
      session[:mno_session_recheck] = @saml_response.attributes['mno_session_recheck']
    end
  end
end