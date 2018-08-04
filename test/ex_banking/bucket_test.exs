defmodule ExBanking.BucketTest do
    use ExUnit.Case, async: true
  
    setup do
      {:ok, bucket} = ExBanking.Bucket.start_link([])
      %{bucket: bucket}
    end
  
    test "store values by key", %{bucket: bucket} do
      assert ExBanking.Bucket.get(bucket, "eur") == nil
      assert ExBanking.Bucket.get(bucket, "usd") == nil
  
      ExBanking.Bucket.put(bucket, "eur", 3.0)
      assert ExBanking.Bucket.get(bucket, "eur") == 3.0
    
      ExBanking.Bucket.put(bucket, "usd", 2.0)
      assert ExBanking.Bucket.get(bucket, "usd") == 2.0
    end
  
  end
  