# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# TODO: permissions
#       review

class PermissionsController < ApplicationController
  load_and_authorize_resource

  def update
    if @permission.update_attributes(permited(params[:permission]))
      flash[:success] = t('permission.update.success')
    else
      flash[:error] = t('permission.update.failure')
    end
    redirect_to request.referer
  end

  def destroy
    @permission.destroy

    respond_to do |format|
      format.html {
        redirect_to request.referer
      }
    end
  end

  def permited obj
    unless obj.nil?
      obj.permit(*allowed_params)
    else
      []
    end
  end

  def allowed_params
    [ :role_id ]
  end
end
