<script lang="ts">
	import Logo from '$lib/components/ui/Logo.svelte';
	import { siteConfig } from '$lib/config';
	import { api, type LoginResponse } from '$lib/api';

	function handleGoogleSignIn() {
		const form = document.createElement('form');
		form.method = 'POST';
		form.action = '/auth/oauth/google';
		document.body.appendChild(form);
		form.submit();
		form.remove();
	}

	let error: string | null = null;

	async function handleSubmit(event: SubmitEvent) {
		console.log('handleSubmit called');
		event.preventDefault();
		error = null;

		const form = event.target as HTMLFormElement;
		const formData = Object.fromEntries(new FormData(form));

		try {
			const response: LoginResponse = await api.LoginPost({
				email: formData.email as string,
				password: formData.password as string
			});

			if (response.status != 'success') {
				error = response.message || 'Login failed. Please try again.';
				return;
			}

			if (response.status === 'success') {
				if (response.message) {
					console.log(response.message);
				}
				if (response.redirectUrl) {
					window.location.href = response.redirectUrl;
				}
			} else {
				error = response.message || 'Login failed. Please try again.';
			}
		} catch (err) {
			error = 'An unexpected error occurred. Please try again.';
			console.error('Login error:', err);
		}
	}
</script>

<div class="z-10 flex flex-col flex-1 px-4 py-10 bg-base-100 md:flex-none md:px-28">
	<main class="w-full max-w-md mx-auto sm:px-4 md:w-96 md:max-w-sm md:px-0">
		<div class="flex">
			<a aria-label="Home" href="/" class="flex flex-row">
				{#if siteConfig.logoSvg}
					<!-- Replace with your Logo component -->
					<Logo fancyBrandName={siteConfig.title} />
					<span class="sr-only">{siteConfig.title}</span>
				{:else if siteConfig.title}
					<h1 class="ml-2 text-2xl font-semibold flex-2">{siteConfig.title}</h1>
				{/if}
			</a>
		</div>

		<h2 class="mt-20 text-lg font-semibold text-base-content">Sign in to your account</h2>

		<div class="mt-6">
			<div class="grid grid-cols-1 gap-4">
				<button on:click={handleGoogleSignIn} class="w-full btn btn-outline">
					<svg class="w-5 h-5" viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M12.0003 4.75C13.7703 4.75 15.3553 5.36002 16.6053 6.54998L20.0303 3.125C17.9502 1.19 15.2353 0 12.0003 0C7.31028 0 3.25527 2.69 1.28027 6.60998L5.27028 9.70498C6.21525 6.86002 8.87028 4.75 12.0003 4.75Z"
							fill="#EA4335"
						></path>
						<path
							d="M23.49 12.275C23.49 11.49 23.415 10.73 23.3 10H12V14.51H18.47C18.18 15.99 17.34 17.25 16.08 18.1L19.945 21.1C22.2 19.01 23.49 15.92 23.49 12.275Z"
							fill="#4285F4"
						></path>
						<path
							d="M5.26498 14.2949C5.02498 13.5699 4.88501 12.7999 4.88501 11.9999C4.88501 11.1999 5.01998 10.4299 5.26498 9.7049L1.275 6.60986C0.46 8.22986 0 10.0599 0 11.9999C0 13.9399 0.46 15.7699 1.28 17.3899L5.26498 14.2949Z"
							fill="#FBBC05"
						></path>
						<path
							d="M12.0004 24.0001C15.2404 24.0001 17.9654 22.935 19.9454 21.095L16.0804 18.095C15.0054 18.82 13.6204 19.245 12.0004 19.245C8.8704 19.245 6.21537 17.135 5.2654 14.29L1.27539 17.385C3.25539 21.31 7.3104 24.0001 12.0004 24.0001Z"
							fill="#34A853"
						></path>
					</svg>
					<span class="text-sm font-semibold leading-6">Google</span>
				</button>
			</div>
		</div>

		<div class="relative mt-10">
			<div class="absolute inset-0 flex items-center" aria-hidden="true">
				<div class="w-full border-t border-base-300"></div>
			</div>
			<div class="relative flex justify-center text-sm font-medium leading-6">
				<span class="px-6 text-base-content bg-base-100">Or continue with email</span>
			</div>
		</div>

		<form on:submit={handleSubmit} class="grid grid-cols-1 mt-10 gap-y-4">
			{#if error}
				<div class="alert alert-error" id="form-error">
					{error}
				</div>
			{/if}
			<div>
				<label for="email" class="w-full form-control">
					<span class="label-text">Email address</span>
					<input
						id="email"
						autocomplete="email"
						required
						class="w-full input input-bordered"
						type="email"
						name="email"
					/>
				</label>
			</div>
			<div>
				<label for="password" class="w-full form-control">
					<span class="label-text">Password</span>
					<input
						id="password"
						autocomplete="current-password"
						required
						class="w-full input input-bordered"
						type="password"
						name="password"
					/>
				</label>
			</div>
			<div>
				<button class="w-full btn btn-primary" type="submit">
					<span>Sign in <span aria-hidden="true">→</span></span>
				</button>
			</div>
		</form>

		<p class="mt-8 text-sm text-center text-base-content/70">
			Don't have an account?
			<a href="/auth/register" class="font-medium link link-primary">Sign up</a> for a free account.
		</p>
	</main>
</div>
<div class="hidden bg-base-200 sm:contents lg:relative lg:block lg:flex-1"></div>
