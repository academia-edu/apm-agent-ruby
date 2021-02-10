# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require 'spec_helper'

require 'aws-sdk-s3'

module ElasticAPM
  RSpec.describe 'Spy: Dalli' do
    it 'spans api calls', :intercept do
      client = Aws::S3::Client.new(stub_responses: true)

      with_agent do
        ElasticAPM.with_transaction do
          client.create_bucket(bucket: 'foo')
        end
      end

      span, = @intercepted.spans

      expect(span.name).to eq 'S3 CreateBucket'
      expect(span.subtype).to eq 'S3'
      expect(span.action).to eq 'CreateBucket'

      http = span.context.http
      expect(http.method).to eq 'PUT'
    end
  end
end