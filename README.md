# PhxHerokuCloudfront

This is a minimum setup for a Phoenix server hosted on Heroku configured with a Cloudfront CDN.

### Running locally

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

### Steps to configure

#### 1. Create our new phoenix project.

```bash
mix phx.new phx_heroku_cloudfront --no-ecto
```

Check that it's all working locally from the steps in the [Running locally](#running-locally) section.

#### 2. Follow the steps from the [Phoenix Heroku deployment guide](https://hexdocs.pm/phoenix/heroku.html).

To see the necessary file changes, see commit [here](https://github.com/samhstn/phx_heroku_cloudfront/commit/759f4acd63fbbebd8c2cedfa338932b4183d0983).

#### 3. Set up our custom domain using Route53, our certificate using ACM and our Cloudfront distribution.

Simply deploy the cloudformation template [`base.yaml`](https://github.com/samhstn/phx_heroku_cloudfront/commit/54b215de2ae408f5edaeb7ecb19df09a506955d9) in the aws cloudformation console.

Then click `Create record in Route 53` for our domains.

After the stack was created, my phoenix application was available at my custom Route53 domain.

When checking our Heroku logs, we can see that when visiting our heroku app via our Heroku url.

For each request, our logs show:

```
2019-11-26T13:00:45.297399+00:00 heroku[router]: at=info method=GET path="/" host=young-cove.herokuapp.com request_id=00b428dc-1ec9-4735-b485-590ee7c8628a fwd="90.220.105.184" dyno=web.1 connect=2ms service=3ms status=200 bytes=2582 protocol=https
2019-11-26T13:00:45.296228+00:00 app[web.1]: 13:00:45.295 request_id=00b428dc-1ec9-4735-b485-590ee7c8628a [info] GET /
2019-11-26T13:00:45.296244+00:00 app[web.1]: 13:00:45.295 request_id=00b428dc-1ec9-4735-b485-590ee7c8628a [info] Sent 200 in 264µs
2019-11-26T13:00:45.465432+00:00 heroku[router]: at=info method=GET path="/js/app-d255e0f04466ade472877808e02adefc.js?vsn=d" host=young-cove.herokuapp.com request_id=46eaa8f4-6ad4-40a4-a678-455312b97694 fwd="90.220.105.184" dyno=web.1 connect=2ms service=6ms status=200 bytes=2170 protocol=https
2019-11-26T13:00:45.511849+00:00 heroku[router]: at=info method=GET path="/images/phoenix-5bd99a0d17dd41bc9d9bf6840abcc089.png?vsn=d" host=young-cove.herokuapp.com request_id=0134d316-201a-42e2-997e-6ea65548e200 fwd="90.220.105.184" dyno=web.1 connect=1ms service=3ms status=200 bytes=14147 protocol=https
2019-11-26T13:00:45.417593+00:00 heroku[router]: at=info method=GET path="/css/app-e46694637b09774dee2b8167f86e4061.css?vsn=d" host=young-cove.herokuapp.com request_id=8b585a85-8055-4dd6-b8c8-915a9610e138 fwd="90.220.105.184" dyno=web.1 connect=1ms service=3ms status=200 bytes=10055 protocol=https
2019-11-26T13:00:45.679678+00:00 heroku[router]: at=info method=GET path="/favicon.ico" host=young-cove.herokuapp.com request_id=3733f757-3cdc-4c5e-8b8e-c8d59b03f15e fwd="90.220.105.184" dyno=web.1 connect=1ms service=3ms status=200 bytes=1518 protocol=https
```

Wheras for each request to https://customdomain.com, we just see the log:

```
2019-11-26T13:02:29.367415+00:00 heroku[router]: at=info method=GET path="/" host=young-cove.herokuapp.com request_id=86fea987-b36d-4e36-bd21-d3ddc656154d fwd="90.220.105.184,70.132.38.80" dyno=web.1 connect=1ms service=8ms status=200 bytes=2582 protocol=https
2019-11-26T13:02:29.359822+00:00 app[web.1]: 13:02:29.359 request_id=86fea987-b36d-4e36-bd21-d3ddc656154d [info] GET /
2019-11-26T13:02:29.360290+00:00 app[web.1]: 13:02:29.360 request_id=86fea987-b36d-4e36-bd21-d3ddc656154d [info] Sent 200 in 552µs
```

This means our CDN is doing its caching job perfectly - see the Chrome `Network` tab for more info.

#### 4. Block direct access to our heroku domain using a redirect plug

We may want to apply further restrictions to our CDN such as a Firewall. So, we really want to block access to our Heroku url. This isn't possible (see: https://stackoverflow.com/a/16910556/4699289), but we can instead look to redirect any incoming request from Heroku to our custom url which has a CDN applied.

Let's add our custom domain:

```bash
heroku domains:add customdomain.com
```

Then let's add a plug at the top of our `endpoint.ex` file which blocks this direct access and redirects to our domain. See changes [here](https://github.com/samhstn/phx_heroku_cloudfront/commit/94cf97bab616d72d54257de6a153003bf12194a7).

Visiting customdomain.com, we get the error: `This page isn’t working customdomain.com redirected you too many times.`

It turns out that is because the `host` is always being sent through to our server as the origin host (see [here](https://aws.amazon.com/premiumsupport/knowledge-center/configure-cloudfront-to-forward-headers/)).

So we need to whitelist the `Host` header, this can be done by updating our `base.yaml` template to forward the `Host` header. See changes [here](https://github.com/samhstn/phx_heroku_cloudfront/commit/b20740e19fc3ce14a436a593e12930eae2947baa).
